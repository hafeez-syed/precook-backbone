module.exports = function(grunt) {

    // Project configuration.
    grunt.initConfig({

        //  project metadata, used by the <banner> directive.
        meta: {},

        // compile and concat coffee
        coffee: {
            compile: {
                files: {
                    'dist/precook.js': ['src/*.coffee']
                }
            }
        },

        // list of files to be minified with UglifyJS.
        min: {
            dist: {
                src: ['dist/precook.js'],
                dest: 'dist/precook.min.js'
            }
        },
        // copy the dist files into the example script
        copy: {
            dist: {
                files: {
                    'example/js/vendor/': 'dist/precook.min.js'
                }
            }
        },

        // uglify-js settings
        uglify: {
            mangle: {toplevel: true},
            squeeze: {dead_code: false},
            codegen: {quote_keys: true}
        }

    });

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-copy');

    // default singular task
    grunt.registerTask('default', 'coffee min copy');

};