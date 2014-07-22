define [
    "underscore"
    "jquery"
    "conda_ui/api"
    "conda_ui/utils"
    "conda_ui/modal"
    "conda_ui/dialog"
], (_, $, api, utils, Modal, Dialog) ->

    class PlanModalView extends Modal.View

        initialize: (options) ->
            @pkg = options.pkg
            @envs = options.envs
            @pkgs = options.pkgs
            @actions = options.actions
            @action = options.action
            @action_noun = if @action is "install" then "Installation" else "Uninstallation"
            @action_verb = if @action is "install" then "installed" else "uninstalled"
            super(options)

        title_text: () -> $("<span>#{@action_noun} plan for </span>").append($('<span>').text(@pkg.get('name')))

        submit_text: () -> "Proceed"

        render_body: () ->
            fetch = @actions['FETCH']
            unlink = @actions['UNLINK']
            link = @actions['LINK']

            $plan = $('<div>')

            if fetch?
                $description = $('<h5>The following packages will be downloaded:</h5>')

                headers = ['Name', 'Version', 'Build', 'Size']
                $headers = $('<tr>').html($('<th>').text(text) for text in headers)

                $rows = for pkg in fetch
                    dist = pkg
                    pkg = api.conda.Package.splitFn pkg
                    pkg.dist = dist
                    info = @pkgs.get_by_dist(pkg.name, pkg.dist)

                    $name = $('<td>').text(pkg.name)
                    $version = $('<td>').text(pkg.version)
                    $build = $('<td>').text(pkg.build)
                    $size = $('<td>').text(utils.human_readable(info.size))

                    $columns = [$name, $version, $build, $size]
                    $('<tr>').html($columns)

                $table = $('<table class="table table-bordered table-striped">')
                $table.append($('<thead>').html($headers))
                $table.append($('<tbody>').html($rows))

                $plan.append([$description, $table])

            if unlink?
                $description = $('<h5>The following packages will be UN-linked:</h5>')

                headers = ['Name', 'Version', 'Build']
                $headers = $('<tr>').html($('<th>').text(text) for text in headers)

                $rows = for pkg in unlink
                    dist = pkg
                    pkg = api.conda.Package.splitFn pkg
                    pkg.dist = dist
                    $name = $('<td class="col-plan-name">').text(pkg.name)
                    $version = $('<td class="col-plan-version">').text(pkg.version)
                    $build = $('<td class="col-plan-build">').text(pkg.build)

                    $columns = [$name, $version, $build]
                    $('<tr>').html($columns)

                $table = $('<table class="table table-bordered table-striped unlink">')
                $table.append($('<thead>').html($headers))
                $table.append($('<tbody>').html($rows))

                $plan.append([$description, $table])

            if link?
                $description = $('<h5>The following packages will be linked:</h5>')

                headers = ['Name', 'Version', 'Build']
                $headers = $('<tr>').html($('<th>').text(text) for text in headers)

                $rows = for pkg in link
                    dist = pkg
                    pkg = api.conda.Package.splitFn pkg
                    pkg.dist = dist
                    $name = $('<td class="col-plan-name">').text(pkg.name)
                    $version = $('<td class="col-plan-version">').text(pkg.version)
                    $build = $('<td class="col-plan-build">').text(pkg.build)

                    $columns = [$name, $version, $build]
                    $('<tr>').html($columns)

                $table = $('<table class="table table-bordered table-striped">')
                $table.append($('<thead>').html($headers))
                $table.append($('<tbody>').html($rows))

                $plan.append([$description, $table])

            @$progress = $('<div class="progress-bar progress-bar-striped active" role="progressbar">')
            @$progress.css 'width', '0%'
            @$progress.hide()
            $plan.append $('<div class="progress">').append @$progress

            $plan

        on_submit: (event) =>
            env = @envs.get_active()
            promise = env.attributes[@action]({
                packages: [@pkg.get('name')]
                progress: true
            })
            promise.progress (info) =>
                @$progress.show()
                progress = 100 * (info.progress / info.maxval)
                percent = progress.toString() + '%'
                @$progress.css 'width', percent

                if typeof info.fetch isnt "undefined"
                    label = 'Fetching... ' + info.fetch
                else
                    label = 'Linking... '
                @$progress.html label
            promise.then(@on_install)

        on_install: (data) =>
            @hide()
            @$progress.removeClass 'progress-bar-info'
            if data.success? and data.success
                @$progress.addClass 'progress-bar-success'
                action_verb = @action_verb
                new Dialog.View({type: "info", message: "#{@pkg.get('name')} was successfully #{action_verb}"}).show()
                @pkgs.fetch(reset: true)
                @envs.fetch(reset: true)
            else
                @$progress.addClass 'progress-bar-error'
                new Dialog.View({type: "error", message: data.error}).show()

    return {View: PlanModalView}
