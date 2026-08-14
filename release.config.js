// Este repo usa squash-merge: el título del PR pasa a ser el mensaje del
// commit final en main. commit-analyzer (preset Angular) solo libera versión
// ante commits fix:/feat:/BREAKING CHANGE -- un título sin ese prefijo
// (p.ej. un nombre de feature sin más) hace que el workflow Release corra en
// verde pero sin publicar nada ("no relevant changes, so no new version is
// released"), y sin release tampoco se genera el APK. Ya pasó una vez en
// dipalza_web_client/dipalza_server (ver docs/frontend-embebido-static.md
// de dipalza_server) y de nuevo acá con el PR #26 (gestión de usuarios +
// cambio de clave obligatorio) -- verificar el título ANTES de mergear.
module.exports = {
  branches: ['main'],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    '@semantic-release/changelog',
    ['@semantic-release/exec', {
      prepareCmd: 'bash scripts/bump_pubspec_version.sh ${nextRelease.version}',
      publishCmd: 'flutter build apk --release && cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/dipalza-release-${nextRelease.version}.apk'
    }],
    ['@semantic-release/git', {
      assets: ['pubspec.yaml', 'CHANGELOG.md'],
      message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}'
    }],
    ['@semantic-release/github', {
      assets: [{ path: 'build/app/outputs/flutter-apk/dipalza-release-*.apk' }]
    }]
  ]
};
