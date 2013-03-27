module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    coffee:
      client:
        files:
          'web/launch.js': 'src/launch.coffee'
      server:
        files:
          'server/main.js': 'src/main.coffee'

  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask 'assets', 'Copy static assets to client', ->
    grunt.file.copy 'vendor/knockout-2.2.1.min.js', 'web/vendor/knockout-2.2.1.min.js'
    grunt.file.copy 'vendor/store-1.3.7.min.js', 'web/vendor/store-1.3.7.min.js'
    grunt.file.copy 'src/chat.css', 'web/chat.css'
    grunt.file.copy 'src/index.html', 'web/index.html'

  grunt.registerTask 'clean', 'Clean out build results', ->
    grunt.file.delete 'server'
    grunt.file.delete 'web'

  grunt.registerTask 'default', 'Clean & build everything', ['clean', 'coffee', 'assets']

