;;; org-dispatch.el --- Run autonomous Org tasks with pi in Herdr  -*- lexical-binding: t; -*-

;; Batch entry points:
;;   org-dispatch-run      watch running tasks, then launch eligible ones
;;   org-dispatch-scan     print the tasks this host would launch
;;   org-dispatch-finish   ID STATE [NOTE], used by the agent to end its task
;;
;; A task is an AUTO heading in Jon's Org agenda files tagged with this host.
;; SCHEDULED delays it; a repeater makes it recur. Settings are properties:
;; REVIEW, DEPLOY, BRANCH, MODEL, DIR.

(require 'org)
(require 'org-id)
(require 'seq)
(require 'subr-x)

(defun org-dispatch--env (name default)
  (let ((value (getenv name)))
    (if (and value (not (string-empty-p value))) value default)))

(defvar org-dispatch-host
  (org-dispatch--env "ORG_DISPATCH_HOST" (car (split-string (system-name) "\\."))))
(defvar org-dispatch-hosts
  (split-string (org-dispatch--env "ORG_DISPATCH_HOSTS" "kit cog")))
(defvar org-dispatch-root
  (expand-file-name (org-dispatch--env "ORG_DISPATCH_ROOT" "~/org/work"))
  "Directory scanned when Jon's Emacs config cannot list agenda files.")
(defvar org-dispatch-emacs-init
  (expand-file-name (org-dispatch--env "ORG_DISPATCH_EMACS_INIT" "~/.config/emacs/init.el"))
  "Jon's Emacs init file, loaded in batch to read `org-agenda-files'.")
(defvar org-dispatch-state-dir
  (expand-file-name "org-dispatch" (org-dispatch--env "XDG_STATE_HOME" "~/.local/state")))
(defvar org-dispatch-prompts
  (expand-file-name (org-dispatch--env "ORG_DISPATCH_PROMPTS" "~/.agents/pi/org-dispatch")))
(defvar org-dispatch-model (getenv "ORG_DISPATCH_MODEL")
  "Model for pi, such as codex-lb/gpt-6.1-sol:high. Nil uses pi's defaults.")
(defvar org-dispatch-max-agents
  (string-to-number (org-dispatch--env "ORG_DISPATCH_MAX_AGENTS" "5")))
(defvar org-dispatch-max-nudges
  (string-to-number (org-dispatch--env "ORG_DISPATCH_MAX_NUDGES" "3")))
(defvar org-dispatch-settle
  (string-to-number (org-dispatch--env "ORG_DISPATCH_SETTLE" "120"))
  "Seconds a heading must stay unchanged before it launches.")
(defvar org-dispatch-nudge-after
  (string-to-number (org-dispatch--env "ORG_DISPATCH_NUDGE_AFTER" "300"))
  "Seconds pi must stay idle in PROG before each nudge.")
(defvar org-dispatch-time-limit
  (string-to-number (org-dispatch--env "ORG_DISPATCH_TIME_LIMIT" "14400")))
(defvar org-dispatch-log-keep
  (string-to-number (org-dispatch--env "ORG_DISPATCH_LOG_KEEP" "14"))
  "Run entries a repeating task keeps in its LOGBOOK; older ones go to archive.org.")

;; Calgary time regardless of the host's zone; date-only SCHEDULED is midnight.
(set-time-zone-rule "America/Edmonton")

(setq org-todo-keywords '((sequence "TODO" "PROG" "EVAL" "HOLD" "|" "DONE")
                          (sequence "AUTO" "|"))
      org-log-into-drawer t
      org-log-done 'time
      org-log-repeat nil
      org-id-track-globally nil
      org-element-use-cache nil
      make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

(defun org-dispatch--log (format-string &rest args)
  (princ (concat (format-time-string "%F %T ") (apply #'format format-string args) "\n")))

;;; Herdr

(defun org-dispatch--herdr (&rest args)
  "Run herdr with ARGS in the default session and return parsed JSON."
  (let ((stderr (make-temp-file "org-dispatch")))
    (unwind-protect
        (with-temp-buffer
          (let ((exit (apply #'call-process "herdr" nil (list t stderr) nil
                             "--session" "default" args)))
            (unless (eq exit 0)
              (error "herdr %s: %s" (string-join args " ")
                     (string-trim (concat (buffer-string)
                                          (with-temp-buffer
                                            (insert-file-contents stderr)
                                            (buffer-string))))))
            (goto-char (point-min))
            (unless (eobp)
              (json-parse-buffer :object-type 'alist :null-object nil :false-object nil))))
      (delete-file stderr))))

(defun org-dispatch--get (object &rest keys)
  (dolist (key keys object)
    (setq object (alist-get key object))))

(defun org-dispatch--agent-status (pane)
  "Return PANE's agent status, or nil when no agent runs there."
  (ignore-errors
    (org-dispatch--get (org-dispatch--herdr "agent" "get" pane) 'result 'agent 'agent_status)))

(defun org-dispatch--pane-session (pane)
  "Return the pi session UUID running in PANE, waiting briefly for Herdr."
  (let (uuid)
    (dotimes (_ 20)
      (unless uuid
        (let ((value (org-dispatch--get (org-dispatch--herdr "pane" "get" pane)
                                        'result 'pane 'agent_session 'value)))
          (if (and value (string-match "\\([0-9a-f]\\{8\\}-[0-9a-f-]\\{27\\}\\)\\.jsonl\\'" value))
              (setq uuid (match-string 1 value))
            (sleep-for 0.5)))))
    (or uuid (error "no pi session reported for %s" pane))))

(defun org-dispatch--live-pane (uuid)
  "Return the pane where pi session UUID is running, if any."
  (seq-some (lambda (agent)
              (and (equal (org-dispatch--get agent 'agent) "pi")
                   (string-search uuid (or (org-dispatch--get agent 'agent_session 'value) ""))
                   (org-dispatch--get agent 'pane_id)))
            (org-dispatch--get (org-dispatch--herdr "agent" "list") 'result 'agents)))

(defun org-dispatch--session-file (uuid)
  (car (append (file-expand-wildcards
                (format "~/.local/state/pi/sessions/*/*_%s.jsonl" uuid) t)
               (file-expand-wildcards
                (format "~/.pi/agent/sessions/*/*_%s.jsonl" uuid) t))))

(defun org-dispatch--notify (title body)
  (ignore-errors
    (org-dispatch--herdr "notification" "show" title "--body" body "--sound" "request")))

;;; Org

(defun org-dispatch--agenda-files ()
  "Jon's `org-agenda-files', read by loading his Emacs config in batch.
Cache the list, and reuse the last good one when the config fails to load,
so a half-edited config does not stop dispatching."
  (let ((cache (expand-file-name "agenda-files" org-dispatch-state-dir))
        files)
    (when (file-readable-p org-dispatch-emacs-init)
      (with-temp-buffer
        (when (eq 0 (call-process
                     (expand-file-name invocation-name invocation-directory) nil '(t nil) nil
                     "--batch" "-l" org-dispatch-emacs-init "--eval"
                     "(dolist (f (org-agenda-files)) (princ (format \"\\norg-dispatch-file:%s\\n\" f)))"))
          (goto-char (point-min))
          (while (re-search-forward "^org-dispatch-file:\\(.+\\)$" nil t)
            (push (match-string 1) files)))))
    (if files
        (progn
          (setq files (nreverse files))
          (make-directory org-dispatch-state-dir t)
          (with-temp-file cache (insert (string-join files "\n"))))
      (org-dispatch--log "could not read org-agenda-files from %s; using %s"
                         org-dispatch-emacs-init
                         (if (file-exists-p cache) "the cached list" org-dispatch-root))
      (setq files (if (file-exists-p cache)
                      (with-temp-buffer
                        (insert-file-contents cache)
                        (split-string (buffer-string) "\n" t))
                    (directory-files-recursively
                     org-dispatch-root "\\.org\\'" nil
                     (lambda (dir) (not (string-prefix-p "." (file-name-nondirectory dir))))))))
    (seq-filter (lambda (file)
                  (and (file-regular-p file)
                       (not (string-search ".sync-conflict-" file))))
                files)))

(defun org-dispatch--files (&optional agenda)
  "AGENDA files, or Jon's agenda files, with an AUTO heading."
  (seq-filter (lambda (file)
                (with-temp-buffer
                  (insert-file-contents file)
                  (re-search-forward "^\\*+ AUTO " nil t)))
              (or agenda (org-dispatch--agenda-files))))

(defun org-dispatch--edit (file id function &optional heading)
  "Call FUNCTION at the heading with ID in FILE, then save.
Without an ID in the file yet, find the HEADING by its text instead. Visit
the file fresh so concurrent edits by agents are not overwritten."
  (let ((buffer (find-file-noselect file t)))
    (unwind-protect
        (with-current-buffer buffer
          (org-mode)
          (let ((position (or (org-find-property "ID" id)
                              (and heading (org-find-exact-headline-in-buffer heading)))))
            (unless position (error "no heading %s in %s" (or heading id) file))
            (goto-char position)
            (prog1 (funcall function)
              (when (buffer-modified-p) (save-buffer)))))
      (kill-buffer buffer))))

(defun org-dispatch--find (id &optional agenda)
  "Return the file holding the heading with ID.
Search AGENDA, or Jon's agenda files."
  (seq-find (lambda (file)
              (with-temp-buffer
                (insert-file-contents file)
                (re-search-forward (format "^[ \t]*:ID:[ \t]+%s[ \t]*$" (regexp-quote id)) nil t)))
            (or agenda (org-dispatch--agenda-files))))

(defun org-dispatch--stamp ()
  (format-time-string (org-time-stamp-format t t)))

(defun org-dispatch--subtree-text ()
  (buffer-substring-no-properties
   (point) (save-excursion (org-end-of-subtree t t) (point))))

(defun org-dispatch--section-stars ()
  "Stars for a direct child of the entry at point."
  (make-string (1+ (org-current-level)) ?*))

(defun org-dispatch--section-bounds (title)
  "Return (BEGIN . END) of the child section TITLE of this entry."
  (save-excursion
    (let ((end (save-excursion (org-end-of-subtree t t) (point))))
      (when (re-search-forward (format "^%s %s[ \t]*$"
                                       (regexp-quote (org-dispatch--section-stars))
                                       (regexp-quote title))
                               end t)
        (let ((begin (match-beginning 0)))
          (goto-char begin)
          (cons begin (save-excursion (org-end-of-subtree t t) (point))))))))

(defun org-dispatch--append (title text)
  "Append TEXT to section TITLE of this entry, creating it when needed.
New sections go before Dialog, which stays last."
  (save-excursion
    (let ((section (org-dispatch--section-bounds title))
          (stars (org-dispatch--section-stars)))
      (if section
          (goto-char (cdr section))
        (goto-char (or (and (not (equal title "Dialog"))
                            (car (org-dispatch--section-bounds "Dialog")))
                       (save-excursion (org-end-of-subtree t t) (point)))))
      (skip-chars-backward " \t\n")
      (end-of-line)
      (insert (if section "\n" (format "\n\n%s %s\n\n" stars title)) text)
      (unless section
        (unless (looking-at-p "\n") (insert "\n"))
        (when (looking-at-p "\n\\*") (insert "\n"))))))

(defun org-dispatch--remove-section (title)
  (let ((section (org-dispatch--section-bounds title)))
    (when section (delete-region (car section) (cdr section)))))

(defun org-dispatch--trim-log (id)
  "Move LOGBOOK entries of the entry at point past `org-dispatch-log-keep'
to a run log heading for ID in archive.org beside this file, newest first."
  (save-excursion
    (let ((limit (save-excursion (outline-next-heading) (point)))
          items)
      (when (re-search-forward "^[ \t]*:LOGBOOK:[ \t]*\n" limit t)
        (let ((end (save-excursion (re-search-forward "^[ \t]*:END:" limit) (match-beginning 0))))
          (while (re-search-forward "^- " end t)
            (push (match-beginning 0) items))
          (setq items (nreverse items))
          (when (> (length items) org-dispatch-log-keep)
            (let ((cut (nth org-dispatch-log-keep items))
                  (heading (org-get-heading t t t t))
                  (olpath (save-excursion
                            (goto-char (org-entry-beginning-position))
                            (string-join (org-get-outline-path) "/")))
                  (category (org-get-category))
                  (source (abbreviate-file-name buffer-file-name)))
              ;; Save the archive before deleting, so a failure loses nothing.
              (org-dispatch--edit-archive
               (expand-file-name "archive.org" (file-name-directory buffer-file-name))
               id (buffer-substring-no-properties cut end)
               (format ":ARCHIVE_FILE: %s\n:ARCHIVE_OLPATH: %s\n:ARCHIVE_CATEGORY: %s\n"
                       source olpath category)
               heading)
              (delete-region cut end))))))))

(defun org-dispatch--edit-archive (file id text properties heading)
  "Insert TEXT at the top of ID's run log in FILE, creating it when needed."
  (let ((buffer (find-file-noselect file t)))
    (unwind-protect
        (with-current-buffer buffer
          (org-mode)
          (let ((position (org-find-property "ARCHIVE_ID" id)))
            (if position
                (goto-char position)
              (goto-char (point-max))
              (unless (bolp) (insert "\n"))
              (insert (format "\n* %s run log\n:PROPERTIES:\n:ARCHIVE_ID: %s\n%s:END:\n"
                              heading id properties))
              (forward-line -1)))
          (org-end-of-meta-data)
          (insert text)
          (save-buffer))
      (kill-buffer buffer))))

(defun org-dispatch--entry (title text)
  "Format a Dialog entry by TITLE with TEXT, indenting continuation lines."
  (format "- %s %s: %s" title (org-dispatch--stamp)
          (replace-regexp-in-string "\n" "\n  " (string-trim text))))

(defun org-dispatch--project-repos (file)
  "Local repository links in FILE's preamble, in either the one-line
=Repository:= form or the =Repositories:= list."
  (with-temp-buffer
    (insert-file-contents file)
    (let (repos (end (or (re-search-forward "^\\* " nil t) (point-max))))
      (goto-char (point-min))
      (while (re-search-forward "\\[\\[file:\\([^]]+\\)\\]\\[local\\]\\]" end t)
        (push (directory-file-name (expand-file-name (match-string 1))) repos))
      (nreverse repos))))

(defun org-dispatch--project-dir (file)
  "The project's only local repository, or the project directory."
  (let ((repos (org-dispatch--project-repos file)))
    (if (= (length repos) 1)
        (car repos)
      (directory-file-name (file-name-directory file)))))

(defun org-dispatch--task ()
  "Describe the entry at point."
  (let* ((tags (org-get-tags nil t))
         (hosts (or (seq-intersection tags org-dispatch-hosts)
                    (seq-intersection org-file-tags org-dispatch-hosts)))
         (section (org-dispatch--section-bounds "Sessions"))
         (dir (org-entry-get nil "DIR"))
         sessions)
    ;; Only the Sessions section names this run's sessions; LOGBOOK holds past runs.
    (when section
      (save-excursion
        (goto-char (car section))
        (while (re-search-forward
                (format "herdr:%s/pi:\\([0-9a-f-]+\\)" (regexp-quote org-dispatch-host))
                (cdr section) t)
          (push (match-string 1) sessions))))
    (list :file buffer-file-name
          :id (org-entry-get nil "ID")
          :heading (org-get-heading t t t t)
          :todo (org-get-todo-state)
          :hosts hosts
          :scheduled (org-get-scheduled-time (point))
          :repeat (org-get-repeat)
          :review (not (equal (downcase (or (org-entry-get nil "REVIEW") "yes")) "no"))
          :deploy (equal (downcase (or (org-entry-get nil "DEPLOY") "no")) "yes")
          :branch (org-entry-get nil "BRANCH")
          :model (or (org-entry-get nil "MODEL") org-dispatch-model)
          :dir (if dir (expand-file-name dir) (org-dispatch--project-dir buffer-file-name))
          :repos (org-dispatch--project-repos buffer-file-name)
          :session (car sessions)
          :dialog (org-dispatch--new-dialog)
          :hash (secure-hash 'sha1 (org-dispatch--subtree-text)))))

(defun org-dispatch--new-dialog ()
  "Dialog entries written since the agent's last entry."
  (let ((section (org-dispatch--section-bounds "Dialog")))
    (when section
      (save-excursion
        (goto-char (car section))
        (forward-line 1)
        (let ((start (point)))
          (while (re-search-forward "^- Agent\\b" (cdr section) t)
            (setq start (if (re-search-forward "^- " (cdr section) t)
                            (match-beginning 0)
                          (cdr section))))
          (let ((text (string-trim (buffer-substring-no-properties start (cdr section)))))
            (unless (string-empty-p text) text)))))))

(defun org-dispatch--tasks (&optional agenda)
  "AUTO headings in AGENDA, or Jon's agenda files."
  (let (tasks)
    (dolist (file (org-dispatch--files agenda))
      (let ((buffer (find-file-noselect file t)))
        (with-current-buffer buffer
          (org-mode)
          (org-map-entries
           (lambda ()
             (let ((task (org-dispatch--task)))
               (when (equal (plist-get task :todo) "AUTO")
                 (push task tasks))))
           "/AUTO"))
        (kill-buffer buffer)))
    (nreverse tasks)))

;;; Local state

(defun org-dispatch--state-file (id)
  (expand-file-name (concat id ".json") org-dispatch-state-dir))

(defun org-dispatch--states ()
  (when (file-directory-p org-dispatch-state-dir)
    (mapcar (lambda (file)
              (with-temp-buffer
                (insert-file-contents file)
                (json-parse-buffer :object-type 'plist :null-object nil :false-object nil)))
            (directory-files org-dispatch-state-dir t "\\`[0-9a-f-]+\\.json\\'"))))

(defun org-dispatch--save-state (state)
  (make-directory org-dispatch-state-dir t)
  (with-temp-file (org-dispatch--state-file (plist-get state :id))
    (insert (json-serialize state))))

(defun org-dispatch--drop-state (id)
  (ignore-errors (delete-file (org-dispatch--state-file id))))

;;; Prompts

(defun org-dispatch--git-p (dir)
  (eq 0 (call-process "git" nil nil nil "-C" dir "rev-parse" "--git-dir")))

(defun org-dispatch--policy (task)
  (string-join
   (delq nil
         (list
          (if (plist-get task :review)
              "- Jon reviews this task. Finish with EVAL, never DONE."
            "- No review is needed. Finish with DONE once your verification passes.")
          (let ((where (if (org-dispatch--git-p (plist-get task :dir))
                           "your work"
                         "your work in each repository you change"))
                (branch (plist-get task :branch)))
            (if (or (org-dispatch--git-p (plist-get task :dir)) (plist-get task :repos))
                (if branch
                    (format "- Commit %s and push it to the branch =%s=, not the default branch."
                            where branch)
                  (format "- Commit %s and push it to the current branch." where))
              "- No repository belongs to this task; there is nothing to commit."))
          (if (plist-get task :deploy)
              "- Deploying is allowed when the task calls for it."
            "- Do not deploy, activate, or install anything system-wide.")
          (when (plist-get task :repeat)
            (concat "- This task repeats. The heading body is standing instructions: do not edit it"
                    " or add Scope, Checklist, or other sections. The finish note becomes the run's"
                    " log entry: one short sentence on what changed, or just \"No change.\""
                    " Do not list the checks you ran."))))
   "\n"))

(defun org-dispatch--render (name task &optional extra)
  "Fill prompt template NAME for TASK. EXTRA is an alist of more placeholders."
  (let ((text (with-temp-buffer
                (insert-file-contents (expand-file-name (concat name ".org") org-dispatch-prompts))
                (buffer-string)))
        (values (append
                 `(("ID" . ,(plist-get task :id))
                   ("FILE" . ,(abbreviate-file-name (plist-get task :file)))
                   ("HEADING" . ,(plist-get task :heading))
                   ("DIR" . ,(abbreviate-file-name (plist-get task :dir)))
                   ("POLICY" . ,(org-dispatch--policy task)))
                 extra)))
    (dolist (pair values text)
      (setq text (string-replace (format "{{%s}}" (car pair)) (or (cdr pair) "") text)))))

(defun org-dispatch--dialog-block (task resumed)
  (cond ((not resumed) "")
        ((plist-get task :dialog)
         (concat "Jon set this task back to TODO. New Dialog entries since your last one:\n\n"
                 "#+begin_quote\n" (plist-get task :dialog) "\n#+end_quote\n"))
        (t "Jon set this task back to TODO without replying. Proceed with the default you stated.\n")))

;;; Launching

(defun org-dispatch--claim (task pane session)
  "Mark TASK in progress and link its SESSION in one edit."
  (let ((link (format "herdr:%s/pi:%s" org-dispatch-host session)))
    (org-dispatch--edit
     (plist-get task :file) (plist-get task :id)
     (lambda ()
       (org-entry-put nil "ID" (plist-get task :id))
       ;; Org resets a repeat to TODO, which is Jon's; keep it AUTO. Also trim
       ;; here: a reviewed repeat is closed in Emacs, not by finish.
       (when (plist-get task :repeat)
         (org-entry-put nil "REPEAT_TO_STATE" "AUTO")
         (org-dispatch--trim-log (plist-get task :id)))
       (org-todo "PROG")
       (unless (let ((section (org-dispatch--section-bounds "Sessions")))
                 (and section (string-search link (buffer-substring-no-properties
                                                   (car section) (cdr section)))))
         (org-dispatch--append
          "Sessions"
          (format "- [[%s@%s][%s · pi · %s]]" link pane org-dispatch-host
                  (format-time-string "%Y-%m-%d %H:%M")))))
     (plist-get task :heading))))

(defun org-dispatch--prompt (pane text)
  (org-dispatch--herdr "agent" "prompt" pane text "--wait" "--until" "working"
                       "--until" "blocked" "--until" "idle" "--until" "done"
                       "--timeout" "60000"))

(defun org-dispatch--launch (task)
  "Start or resume pi for TASK in Herdr and claim it. Return non-nil on success."
  (let* ((id (or (plist-get task :id) (org-id-new)))
         (task (plist-put (copy-sequence task) :id id))
         (resume (plist-get task :session))
         (pane (and resume (org-dispatch--live-pane resume)))
         (workspace nil)
         (label (truncate-string-to-width (concat "auto · " (plist-get task :heading)) 60))
         (state (list :id id :file (plist-get task :file) :heading (plist-get task :heading)
                      :dir (plist-get task :dir) :status "starting"
                      :started (float-time) :nudges 0
                      :repeat (if (plist-get task :repeat) 1 0))))
    (org-dispatch--save-state state)
    (condition-case err
        (progn
          (unless pane
            (let ((created (org-dispatch--herdr "workspace" "create" "--cwd" (plist-get task :dir)
                                                "--label" label "--no-focus")))
              (setq pane (org-dispatch--get created 'result 'root_pane 'pane_id)
                    workspace (org-dispatch--get created 'result 'workspace 'workspace_id)))
            (apply #'org-dispatch--herdr "agent" "start"
                   (format "auto-%s-%s"
                           (substring (replace-regexp-in-string "[^0-9a-f]" "" id) 0 8)
                           (format-time-string "%H%M%S"))
                   "--kind" "pi" "--pane" pane "--timeout" "60000" "--"
                   "--no-approve" "--name" label
                   (append
                    (when (plist-get task :model) (list "--model" (plist-get task :model)))
                    (when resume
                      (list "--session" (or (org-dispatch--session-file resume) resume))))))
          (let ((session (org-dispatch--pane-session pane)))
            (org-dispatch--claim task pane session)
            (setq state (plist-put state :pane pane))
            (setq state (plist-put state :workspace (or workspace "")))
            (setq state (plist-put state :session session))
            (setq state (plist-put state :status "running"))
            (org-dispatch--save-state state)
            ;; Claimed: a failed prompt leaves pi idle, which the watcher nudges.
            (condition-case err
                (org-dispatch--prompt
                 pane (org-dispatch--render
                       "task" task `(("DIALOG" . ,(org-dispatch--dialog-block task resume)))))
              (error (org-dispatch--log "prompt failed for %s: %s" id (error-message-string err))))
            (org-dispatch--log "%s %s: %s in %s" (if resume "resumed" "launched")
                               id (plist-get task :heading) pane)
            t))
      (error
       (org-dispatch--drop-state id)
       (org-dispatch--log "launch failed for %s: %s"
                          (plist-get task :heading) (error-message-string err))
       nil))))

;;; Watching

(defun org-dispatch--hold (state reason)
  "Set STATE's task to HOLD with a Dispatcher entry giving REASON."
  (org-dispatch--edit (plist-get state :file) (plist-get state :id)
                      (lambda ()
                        (org-todo "HOLD")
                        (org-dispatch--append "Dialog" (org-dispatch--entry "Dispatcher" reason))))
  (org-dispatch--drop-state (plist-get state :id))
  (org-dispatch--notify (concat "HOLD · " (plist-get state :heading)) reason)
  (org-dispatch--log "held %s: %s" (plist-get state :id) reason))

(defun org-dispatch--todo-state (state)
  "Current TODO keyword of STATE's heading, or nil when it is gone."
  (let ((file (if (file-exists-p (plist-get state :file))
                  (plist-get state :file)
                (org-dispatch--find (plist-get state :id)))))
    (when file
      (setq state (plist-put state :file file))
      (ignore-errors
        (org-dispatch--edit file (plist-get state :id) #'org-get-todo-state)))))

(defun org-dispatch--watch (state)
  (let* ((id (plist-get state :id))
         (pane (plist-get state :pane))
         (todo (org-dispatch--todo-state state))
         (status (and pane (org-dispatch--agent-status pane)))
         (nudges (plist-get state :nudges)))
    (cond
     ((equal (plist-get state :status) "finished")
      ;; Close workspaces this dispatcher opened once their work is accepted.
      (unless (member status '("working" "blocked"))
        (when (and (member todo '("DONE" "AUTO"))
                   (not (string-empty-p (or (plist-get state :workspace) ""))))
          (ignore-errors (org-dispatch--herdr "workspace" "close" (plist-get state :workspace))))
        (org-dispatch--drop-state id)))
     ((not (equal (plist-get state :status) "running"))
      ;; A launch that died part way leaves a "starting" entry behind.
      (when (> (- (float-time) (plist-get state :started)) 600)
        (org-dispatch--drop-state id)))
     ((null todo)
      (org-dispatch--log "dropped %s: heading not found" id)
      (org-dispatch--drop-state id))
     ((not (equal todo "PROG"))
      ;; Jon changed the state while the agent ran.
      (when (member status '("working" "blocked"))
        (ignore-errors (org-dispatch--herdr "agent" "send-keys" pane "esc"))
        (org-dispatch--log "interrupted %s: Jon set %s" id todo))
      (org-dispatch--drop-state id))
     ((> (- (float-time) (plist-get state :started)) org-dispatch-time-limit)
      (ignore-errors (org-dispatch--herdr "agent" "send-keys" pane "esc"))
      (org-dispatch--hold state (format "Interrupted after %d minutes without finishing."
                                        (/ org-dispatch-time-limit 60))))
     ((null status)
      (org-dispatch--hold state "pi is no longer running in its pane."))
     ((equal status "blocked")
      (when (eq (plist-get state :blocked) 0)
        (org-dispatch--notify (concat "Blocked · " (plist-get state :heading))
                              "pi is waiting on an approval prompt."))
      (org-dispatch--save-state (plist-put state :blocked 1)))
     ((member status '("idle" "done"))
      (let* ((idle (plist-get state :idle))
             (since (if (and idle (> idle 0)) idle (float-time))))
        (setq state (plist-put state :idle since))
        (cond
         ((< (- (float-time) since) org-dispatch-nudge-after)
          (org-dispatch--save-state state))
         ((>= nudges org-dispatch-max-nudges)
          (org-dispatch--hold state (format "Still idle without a state change after %d nudge%s."
                                            org-dispatch-max-nudges
                                            (if (= org-dispatch-max-nudges 1) "" "s"))))
         (t
          (setq state (plist-put state :nudges (1+ nudges)))
          (setq state (plist-put state :idle 0))
          (org-dispatch--save-state state)
          (org-dispatch--prompt
           pane (org-dispatch--render
                 "nudge" state `(("NUDGE" . ,(number-to-string (1+ nudges)))
                                 ("MAX" . ,(number-to-string org-dispatch-max-nudges)))))
          (org-dispatch--log "nudged %s (%d of %d)" id (1+ nudges) org-dispatch-max-nudges)))))
     (t (setq state (plist-put state :blocked 0))
        (org-dispatch--save-state (plist-put state :idle 0))))))

;;; Entry points

(defun org-dispatch--pending-file ()
  (expand-file-name "pending.json" org-dispatch-state-dir))

(defun org-dispatch--eligible (tasks states &optional dry-run)
  "TASKS this host may launch now, respecting STATES already running.
A task launches only after its text stays unchanged for
`org-dispatch-settle' seconds, so a heading still being typed waits.
DRY-RUN marks waiting tasks with :waiting instead of recording progress."
  (let* ((now (float-time))
         (file (org-dispatch--pending-file))
         (old (if (file-exists-p file)
                  (with-temp-buffer (insert-file-contents file) (json-parse-buffer))
                (make-hash-table :test 'equal)))
         (new (make-hash-table :test 'equal))
         (running (seq-filter (lambda (s) (member (plist-get s :status) '("running" "starting")))
                              states))
         eligible)
    (dolist (task tasks)
      (let* ((hosts (plist-get task :hosts))
             (key (or (plist-get task :id)
                      (concat (plist-get task :file) "::" (plist-get task :heading))))
             (seen (gethash key old))
             (same (and seen (equal (gethash "hash" seen) (plist-get task :hash))))
             (entry (if same seen
                      (let ((entry (make-hash-table :test 'equal)))
                        (puthash "hash" (plist-get task :hash) entry)
                        (puthash "seen" now entry)
                        entry))))
        (cond
         ((> (length hosts) 1)
          (unless same
            (org-dispatch--log "skipped %s: tagged for %s" (plist-get task :heading)
                               (string-join hosts " and ")))
          (puthash key entry new))
         ((not (equal hosts (list org-dispatch-host))))
         ;; Record text before checking SCHEDULED, so a task written ahead of
         ;; time starts on schedule instead of settling then.
         ((progn (puthash key entry new) nil))
         ((and (plist-get task :scheduled) (time-less-p now (plist-get task :scheduled))))
         ((seq-find (lambda (s) (equal (plist-get s :id) (plist-get task :id))) running))
         ((< (- now (gethash "seen" entry)) org-dispatch-settle)
          (when dry-run (push (plist-put task :waiting t) eligible)))
         ((seq-find (lambda (s) (equal (plist-get s :dir) (plist-get task :dir)))
                    (append running eligible)))
         ((>= (+ (length running) (length eligible)) org-dispatch-max-agents))
         (t (push task eligible)))))
    (unless dry-run
      (make-directory org-dispatch-state-dir t)
      (with-temp-file file (insert (json-serialize new))))
    (nreverse eligible)))

(defun org-dispatch-run ()
  (dolist (state (org-dispatch--states))
    (condition-case err
        (org-dispatch--watch state)
      (error (org-dispatch--log "watch failed for %s: %s"
                                (plist-get state :id) (error-message-string err)))))
  (dolist (task (org-dispatch--eligible (org-dispatch--tasks) (org-dispatch--states)))
    (org-dispatch--launch task)))

(defun org-dispatch-scan ()
  (dolist (task (org-dispatch--eligible (org-dispatch--tasks) (org-dispatch--states) t))
    (princ (format "%s\t%s\t%s\n" (plist-get task :heading)
                   (abbreviate-file-name (plist-get task :dir))
                   (cond ((plist-get task :waiting) "settling")
                         ((plist-get task :session) "resume")
                         (t "new"))))))

(defun org-dispatch-finish ()
  "Finish a task: ID STATE [NOTE] from the command line."
  (let* ((id (pop command-line-args-left))
         (todo (upcase (or (pop command-line-args-left) "")))
         (note (string-trim (string-join command-line-args-left " ")))
         (file (or (org-dispatch--find id) (error "no heading with ID %s" id)))
         (state-file (org-dispatch--state-file id))
         (state (and (file-exists-p state-file)
                     (with-temp-buffer
                       (insert-file-contents state-file)
                       (json-parse-buffer :object-type 'plist :null-object nil :false-object nil))))
         result)
    (setq command-line-args-left nil)
    (unless (member todo '("EVAL" "HOLD" "DONE"))
      (error "STATE must be EVAL, HOLD, or DONE"))
    (when (and (equal todo "HOLD") (string-empty-p note))
      (error "HOLD needs a question for Jon"))
    (setq result
          (org-dispatch--edit
           file id
           (lambda ()
             (let ((task (org-dispatch--task)))
               (when (and (equal todo "DONE") (plist-get task :review))
                 (setq todo "EVAL"))
               (cond
                ((equal todo "HOLD")
                 (org-dispatch--append "Dialog" (org-dispatch--entry "Agent" note)))
                ((and (equal todo "DONE") (plist-get task :repeat))
                 (let ((links (save-excursion
                                (let ((section (org-dispatch--section-bounds "Sessions")) found)
                                  (when section
                                    (goto-char (car section))
                                    (while (re-search-forward "\\[\\[herdr:[^]]+\\]\\[[^]]+\\]\\]"
                                                              (cdr section) t)
                                      (push (match-string 0) found)))
                                  (nreverse found)))))
                   (org-dispatch--remove-section "Dialog")
                   (org-dispatch--remove-section "Sessions")
                   (save-excursion
                     (goto-char (org-log-beginning t))
                     (insert (format "- State %-12s from %-12s %s \\\\\n  %s\n"
                                     "\"DONE\"" (format "\"%s\"" (plist-get task :todo))
                                     (org-dispatch--stamp)
                                     (string-trim (concat (string-join links " ") " " note)))))
                   (org-dispatch--trim-log id))))
               (org-todo todo)
               (org-get-todo-state)))))
    (when state
      (org-dispatch--save-state (plist-put state :status "finished")))
    (org-dispatch--notify (format "%s · %s" todo (or (plist-get state :heading) id))
                          (if (string-empty-p note) "Finished." note))
    (princ (format "%s is now %s\n" id result))
    (when (equal result "AUTO")
      (princ "The repeat was logged and the next run is scheduled.\n"))))

(provide 'org-dispatch)
;;; org-dispatch.el ends here
