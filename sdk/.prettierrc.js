module.exports = {
  singleQuote: true,
  bracketSpacing: false,
  overrides: [
    {
      files: '*.ts',
      options: {
        printWidth: 120,
        tabWidth: 4,
        singleQuote: false,
      },
    },
  ],
}
