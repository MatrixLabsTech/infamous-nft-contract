const CracoLessPlugin = require('craco-less')

module.exports = {
  reactScriptsVersion: 'react-scripts' /* (default value) */,
  plugins: [
    {
      plugin: CracoLessPlugin,
      options: {
        lessLoaderOptions: {
          lessOptions: {
            modifyVars: {
              '@primary-color': '#F3B74F',
            },
            javascriptEnabled: true,
            sourceMap: true,
          },
          sourceMap: true,
        },
        sourceMap: true,
        cssLoaderOptions: {
          modules: {
            localIdentName: '[path][name]__[local]--[hash:base64:5]',
          },
          sourceMap: true,
        },
      },
    },
  ],
  webpack: {
    configure: (webpackConfig) => {
      webpackConfig.resolve.fallback = {
        stream: require.resolve('stream-browserify'),
      }
      return webpackConfig
    },
  },
}
