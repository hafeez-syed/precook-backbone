root = exports ? this

class AssetVideoLoader

    _sourceFile: ''

    constructor: ->
        # mixin eventing methods (on, off, trigger)
        _.extend @, Backbone.Events

    setSourceFile: (sourceFile) ->
        if Modernizr.video.webm
            sourceFile = @_swapExtension sourceFile, 'webm'
        else if Modernizr.video.h264
            sourceFile = @_swapExtension sourceFile, 'mp4'
        else if Modernizr.video.ogg
            sourceFile = @_swapExtension sourceFile, 'ogv'

        @_sourceFile = sourceFile

    _swapExtension: (file, extension) ->
        filename = file.substr 0, file.lastIndexOf(".")
        return "#{ filename }.#{ extension }"

    load: ->
        @video = $("<video/>",
            src: @_sourceFile
            preload: 'auto'
        )

        $(@video).bind 'canplaythrough load error', (event) =>
            @complete()

    complete: ->
        $(@video).unbind()
        @.trigger 'asset:completed'

root.PrecookVideo = AssetVideoLoader