module.exports = {
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    ['@semantic-release/github', {
      "assets": [
        {"path": "package.json", "label": "package.json"},
      ],
    }],
    '@semantic-release/apm',
  ],
};
