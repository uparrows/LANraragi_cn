/**
 * Plugins Operations.
 */
const Plugins = {};

Plugins.initializeAll = function () {
    // bind events to DOM
    $(document).on("click.save", "#save", () => Server.saveFormData("#editPluginForm"));
    $(document).on("click.return", "#return", () => { window.location.href = "/"; });

    // Handler for file uploading.
    $("#fileupload").fileupload({
        url: "/config/plugins/upload",
        dataType: "json",
        done(e, data) {
            if (data.result.success) {
                LRR.toast({
                    heading: "插件上传成功!",
                    text: `该插件 "${data.result.name}" 已添加成功. 刷新页面即可查看.`,
                    icon: "info",
                    hideAfter: 10000,
                });
            } else {
                LRR.toast({
                    heading: "上传插件出错",
                    text: data.result.error,
                    icon: "error",
                    hideAfter: false,
                });
            }
        },

    });
};

jQuery(() => {
    Plugins.initializeAll();
});
