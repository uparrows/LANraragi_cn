// JS functions meant for use in the Edit page.
// Mostly dealing with plugins.

const Edit = {};
Edit.tagInput = {};
Edit.suggestions = [];

Edit.initializeAll = function () {
    // bind events to DOM
    $(document).on("load.style", "body", set_style_from_storage);
    $(document).on("click.show-help", "#show-help", Edit.showHelp);
    $(document).on("click.run-plugin", "#run-plugin", Edit.runPlugin);
    $(document).on("click.save-metadata", "#save-metadata", Edit.saveMetadata);
    $(document).on("change.plugin", "#plugin", Edit.updateOneShotArg);

    Edit.updateOneShotArg();

    genericAPICall("/api/database/stats?minweight=2", "GET", null, "无法加载标签统计信息",
        (data) => {
            Edit.suggestions = data.reduce((res, tag) => {
                let label = tag.text;
                if (tag.namespace !== "") { label = `${tag.namespace}:${tag.text}`; }
                res.push(label);
                return res;
            }, []);
        })
        .finally(() => {
            const input = $("#tagText")[0];
            Edit.tagInput = tagger(input, {
                allow_duplicates: false,
                allow_spaces: true,
                wrap: true,
                completion: {
                    list: Edit.suggestions,
                },
                link: (name) => `/?q=${name}`,
            });
        });
};

Edit.showHelp = function () {
    $.toast({
        heading: "About Plugins",
        text: "您可以使用插件自动获取此存档的元数据。 <br/> 只需从下拉菜单中选择一个插件，然后点击 Go！<br/> 某些插件可能会提供一个可选参数供您指定。 如果是这种情况，一个文本框将可用于输入所述参数。",
        hideAfter: false,
        position: "top-left",
        icon: "info",
    });
};

Edit.updateOneShotArg = function () {
    // show input
    $("#arg_label").show();
    $("#arg").show();

    const arg = `${$("#plugin").find(":selected").get(0).getAttribute("arg")} : `;

    // hide input for plugins without a oneshot argument field
    if (arg === " : ") {
        $("#arg_label").hide();
        $("#arg").hide();
    }

    $("#arg_label").html(arg);
};

Edit.saveMetadata = function () {
    $("#tag-spinner").css("display", "block");
    $("#tagText").css("opacity", "0.5");
    $("#tagText").prop("disabled", true);
    $("#plugin-table").hide();

    const id = $("#archiveID").val();

    const formData = new FormData();
    formData.append("tags", $("#tagText").val());
    formData.append("title", $("#title").val());

    return fetch(`api/archives/${id}/metadata`, { method: "PUT", body: formData })
        .then((response) => (response.ok ? response.json() : { success: 0, error: "响应不正确" }))
        .then((data) => {
            if (data.success) {
                $.toast({
                    showHideTransition: "slide",
                    position: "top-left",
                    loader: false,
                    heading: "元数据已保存！",
                    icon: "success",
                });
            } else {
                throw new Error(data.message);
            }
        })
        .catch((error) => showErrorToast("保存存档数据时出错 :", error))
        .finally(() => {
            $("#tag-spinner").css("display", "none");
            $("#tagText").prop("disabled", false);
            $("#tagText").css("opacity", "1");
            $("#plugin-table").show();
        });
};

Edit.getTags = function () {
    $("#tag-spinner").css("display", "block");
    $("#tagText").css("opacity", "0.5");
    $("#tagText").prop("disabled", true);
    $("#plugin-table").hide();

    const pluginID = $("select#plugin option:checked").val();
    const archivID = $("#archiveID").val();
    const pluginArg = $("#arg").val();
    genericAPICall(`../api/plugins/use?plugin=${pluginID}&id=${archivID}&arg=${pluginArg}`, "POST", null,
        "Error while fetching tags :", (result) => {
            if (result.data.title && result.data.title != "") {
                $("#title").val(result.data.title);
                $.toast({
                    showHideTransition: "slide",
                    position: "top-left",
                    loader: false,
                    heading: "存档标题更改为 :",
                    text: result.data.title,
                    icon: "info",
                });
            }

            if (result.data.new_tags !== "") {
                result.data.new_tags.split(/,\s?/).forEach((tag) => {
                    Edit.tagInput.add_tag(tag);
                });

                $.toast({
                    showHideTransition: "slide",
                    position: "top-left",
                    loader: false,
                    heading: "添加了以下标签 :",
                    text: result.data.new_tags,
                    icon: "info",
                });
            } else {
                $.toast({
                    showHideTransition: "slide",
                    position: "top-left",
                    loader: false,
                    heading: "没有添加新标签！",
                    text: result.data.new_tags,
                    icon: "info",
                });
            }
        }).finally(() => {
        $("#tag-spinner").css("display", "none");
        $("#tagText").prop("disabled", false);
        $("#tagText").css("opacity", "1");
        $("#plugin-table").show();
    });
};

Edit.runPlugin = function () {
    Edit.saveMetadata().then(() => Edit.getTags());
};

$(document).ready(() => {
    Edit.initializeAll();
});

window.Edit = Edit;
