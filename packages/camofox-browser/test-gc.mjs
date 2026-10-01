// Allocation-driven GC reproduces nodejs/node#65446; explicit gc() does not.
import vm from 'node:vm';
import { pathToFileURL } from 'node:url';

const { sampleWebGL } = await import(pathToFileURL(
  `${process.argv[2]}/lib/node_modules/camofox-browser/node_modules/camoufox-js/dist/webgl/sample.js`,
));
for (let attempt = 0; attempt < 20; attempt++) {
  await sampleWebGL('lin');
  vm.runInNewContext(`
    for (let i = 0; i < 100; i++) {
      const memory = Array.from({length: 10000}, (_, i) => ({i}));
    }
  `);
  await new Promise(resolve => setImmediate(resolve));
}
console.log('WebGL SQLite allocation-driven GC passed');
