import esbuild from 'esbuild';

esbuild.build({
  entryPoints: ['./src/main.ts'],
  bundle: true,
  outfile: './dist/bundle.js',
  platform: 'node',
  target: 'node18',
  minify: true,
  format: 'cjs',
}).catch(() => process.exit(1));