const Hexo = require('hexo');
const hexo = new Hexo(process.cwd(), { silent: false });

hexo.init().then(() => {
  console.log('Hexo initialized successfully');
  return hexo.load();
}).then(() => {
  console.log('Hexo plugins loaded');
  return hexo.call('server', {});
}).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
