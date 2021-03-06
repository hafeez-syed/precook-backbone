root = exports ? this

class AssetLoader

    # Define our loader types. New loaders can be added via ::newLoader()
    _loaders:
        image: -> new PrecookImage
        video: -> new PrecookVideo

    # Used to match asset file extensions to a loader type.
    _types:
        image: ['png', 'jpg', 'jpeg', 'gif']
        video: ['mp4', 'webm', 'ogv']

    constructor: ->
        @_config = null
        @_toLoad = []
        @_numToLoad = 0
        @_numLoaded = 0
        @_group = ''
        @_groups = []

        # mixin eventing methods (on, off, trigger)
        _.extend @, Backbone.Events

    ###
        Initialise the AssetLoader with configuration determining the assets to be loaded.
        Fires a callback (preloader:configLoaded) when this process has completed.

        @param {object} source A JSON object of configuration data OR
        @param {string} source A URL to load JSON configuration data from
    ###
    setConfig: (source) ->
        return @_configFromObject source if _.isObject source

        # retrieve the config json from the server
        jsonRequest = $.getJSON source

        # success
        jsonRequest.done (data, event) =>
            if not data.GROUPS?
                throw new Error 'Invalid JSON format passed to the preloader configuration.'

            @_config = data
            @.trigger 'preloader:configLoaded'

        # failure
        jsonRequest.fail (data, event) =>
            # we shouldn't halt the application from displaying if we can't retrieve the preloader
            # configuration. Signal the application to continue.
            @.trigger 'preloader:configLoaded'

        return

    ###
        Actually load a group/s of assets. Assets for the group are assigned to a loader tpe
        and then loaded. The exact loading functionality is determined by the loader type.

        @param {array} groups Array of group key strings to be loaded.
    ###
    load: (groups...) ->
        # abort loading if there's nothing to load - we don't want to block the app
        return @_finished() if not @_config?

        # make sure the preload group exists in the config
        for group in groups
            if not @_config.GROUPS[group]?
                throw new Error "Invalid group (#{ group }) passed to preloader."

            @_groups.push @_config.GROUPS[group]

        # store the first group passed in as a reference for triggering completed
        @_group = groups[0]

        # merge all assets into a single array
        @_groups = [].concat @_groups...

        @_addAsset asset for asset in @_groups
        @_startLoader asset for asset in @_toLoad

    ###
     * [newLoader expose a Loader to be used for a set of file extensions]
     * @param  {[object]} config { type: 'image', loader: PrecookVideo, types: ['png', 'jpg', 'jpeg', 'gif'] }
     * @return {}
    ###
    newLoader: (config) ->
        @_loaders[config.type] = -> new config.loader
        @_types[config.type] = config.types

    # internal
    #
    _configFromObject: (data) ->
        @_config = data
        @.trigger 'preloader:configLoaded'

    _resetLoader: ->
        # remove all assets from memory
        @_removeAsset asset for asset in @_toLoad

        # reset lists
        @_toLoad = []
        @_numToLoad = @_numLoaded = 0
        @_group = null
        @_groups = []

    _removeAsset: (asset) ->
        # disable all events on assets to remove pointers
        asset.off 'asset:completed'

        # set asset to null
        asset = null

    _addAsset: (src) ->
        type = @_determineType src
        if not type
            throw new Error "Unable to determine asset type for #{ src }"

        # create a new asset loader based on the this asset's type
        loader = @_getLoader type
        url = src
        url = @_config.BASE_URL + url if @_config.BASE_URL?
        loader.setSourceFile url

        # track the list of assets to load
        @_toLoad.push loader
        @_numToLoad += 1

    _determineType: (file) ->
        extension = file.substr (file.lastIndexOf(".") + 1), file.length

        for type, extensions of @_types
            return type if extension in extensions

        return false

    _getLoader: (type) ->
        return @_loaders[type]()

    _startLoader: (asset) ->
        asset.on 'asset:completed', =>
            @_numLoaded += 1
            @_checkFinished()

        asset.load()

    _checkFinished: ->
        return @_finished() if @_numToLoad is @_numLoaded

    _finished: ->
        currentGroup = @_group

        # memory mgmt
        @_resetLoader()

        @.trigger 'preloader:completed', currentGroup

root.Precook = AssetLoader