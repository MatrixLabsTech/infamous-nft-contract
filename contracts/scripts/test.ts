async function main() {
  console.log(process.argv[2])
}

if (require.main === module) {
  main().then(() => process.exit(0))
}
