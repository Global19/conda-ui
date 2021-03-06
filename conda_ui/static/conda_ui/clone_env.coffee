define [
    "jquery"
    "conda_ui/api"
    "conda_ui/env_modal"
], ($, api, EnvModal) ->

    class CloneEnvView extends EnvModal.View

        title_text: () -> "Clone environment"

        submit_text: () -> "Clone"

        doit: (new_name) ->
            progress = @envs.get_active().attributes.clone({
                name: new_name
                progress: true
                forcePscheck: true
            })
            progress.then @on_env_clone(new_name)

            @add_progress(progress)
            @disable_buttons()

        on_env_clone: (new_name) =>
            (data) =>
                @hide()
                env = data.env
                Promise.all([env.linked(), env.revisions()]).then =>
                    @envs.add env
                    @envs.set_active new_name
                    @envs.reset(@envs.models)

    return {View: CloneEnvView}
