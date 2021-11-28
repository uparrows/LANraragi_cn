/**
 * Batch Operations.
 */
const Batch = {};

Batch.socket = {};
Batch.treatedArchives = 0;
Batch.totalArchives = 0;
Batch.currentOperation = "";
Batch.currentPlugin = "";

Batch.initializeAll = function () {
    // bind events to DOM
    $(document).on("change.batch-operation", "#batch-operation", Batch.selectOperation);
    $(document).on("change.plugin", "#plugin", Batch.showOverride);
    $(document).on("click.override", "#override", Batch.showOverride);
    $(document).on("click.check-uncheck", "#check-uncheck", Batch.checkAll);
    $(document).on("click.start-batch", "#start-batch", Batch.startBatch);
    $(document).on("click.restart-job", "#restart-job", Batch.restartBatchUI);
    $(document).on("click.cancel-job", "#cancel-job", Batch.cancelBatch);

    Batch.selectOperation();
    Batch.showOverride();

    // Load all archives, showing a spinner while doing so
    $("#arclist").hide();

    Server.callAPI("/api/archives", "GET", null, "无法加载完整的存档列表！ 请重新加载页面.",
        (data) => {
            // Parse the archive list and add <li> elements to arclist
            data.forEach((archive) => {
                const escapedTitle = LRR.encodeHTML(archive.title) + (archive.isnew === "true" ? " 🆕" : "");
                const html = `<li><input type='checkbox' name='archive' id='${archive.arcid}' class='archive' ><label for='${archive.arcid}'>${escapedTitle}</label></li>`;
                $("#arclist").append(html);
            });

            Batch.checkUntagged();
        })
        .finally(() => {
            $("#arclist").show();
            $("#loading-placeholder").hide();
        });
};

/**
 * Show the matching rows depending on the selected operation.
 */
Batch.selectOperation = function () {
    Batch.currentOperation = $("#batch-operation").val();

    $(".operation").hide();
    $(`.${Batch.currentOperation}-operation`).show();
};

/**
 * Show the matching override arguments for the selected plugin.
 */
Batch.showOverride = function () {
    Batch.currentPlugin = $("#plugin").val();

    const cooldown = $(`#${Batch.currentPlugin}-timeout`).html();
    $("#cooldown").html(cooldown);
    $("#timeout").val(cooldown);

    $(".arg-override").hide();

    if ($("#override")[0].checked) { $(`.${Batch.currentPlugin}-arg`).show(); }
};

/**
 * Check untagged archives, using the matching API endpoint.
 */
Batch.checkUntagged = function () {
    Server.callAPI("api/archives/untagged", "GET", null, "获取未加标签的存档时出错！",
        (data) => {
            // Check untagged archives
            data.forEach((id) => {
                const checkbox = document.getElementById(id);

                if (checkbox != null) {
                    checkbox.checked = true;
                    // Prepend matching <li> element to the top of the list
                    checkbox.parentElement.parentElement.prepend(checkbox.parentElement);
                }
            });
        });
};

/**
 * Get the titles who have been checked in the batch tagging list, and update their tags.
 * This crafts a JSON list to send to the batch tagging websocket service.
 */
Batch.startBatch = function () {
    if (Batch.currentOperation === "delete" && !confirm("这是破坏性的操作！ 您确定要删除选定的档案吗？")) {
        return;
    }

    $(".tag-options").hide();

    $("#log-container").html("开始批量获取标签操作...\n************\n");
    $("#cancel-job").show();
    $("#restart-job").hide();
    $(".job-status").show();

    const checkeds = document.querySelectorAll("input[name=archive]:checked");

    // Extract IDs from nodelist
    const arcs = [];
    const args = [];

    for (let i = 0, ref = arcs.length = checkeds.length; i < ref; i++) {
        arcs[i] = checkeds[i].id;
    }

    // Reset counts
    Batch.treatedArchives = 0;
    Batch.totalArchives = arcs.length;
    $("#arcs").html(0);
    $("#totalarcs").html(arcs.length);
    $(".bar").attr("style", "width: 0%;");

    // Only add values into the override argument array if the checkbox is on
    const arginputs = $(`.${Batch.currentPlugin}-argvalue`);
    if ($("#override")[0].checked) {
        for (let j = 0, ref = args.length = arginputs.length; j < ref; j++) {
            // Checkbox inputs are handled by looking at the checked prop instead of the value.
            if (arginputs[j].type !== "checkbox") {
                args[j] = arginputs[j].value;
            } else {
                args[j] = arginputs[j].checked ? 1 : 0;
            }
        }
    }

    // Initialize websocket connection
    const timeout = (Batch.currentOperation === "plugin") ? $("#timeout").val() : 0;
    const commandBase = {
        operation: Batch.currentOperation,
        plugin: Batch.currentPlugin,
        args,
    };

    // Close any existing connection
    // eslint-disable-next-line no-empty
    try { Batch.socket.close(); } catch {}

    let wsProto = "ws://";
    if (document.location.protocol === "https:") wsProto = "wss://";
    Batch.socket = new WebSocket(`${wsProto + window.location.host}/batch/socket`);

    Batch.socket.onopen = function () {
        const command = commandBase;
        command.archive = arcs.splice(0, 1)[0];
        // eslint-disable-next-line no-console
        console.log(command);
        Batch.socket.send(JSON.stringify(command));
    };

    Batch.socket.onmessage = function (event) {
        // Update log
        Batch.updateBatchStatus(event);

        // If there are no archives left, end session
        if (arcs.length === 0) {
            Batch.socket.close(1000);
            return;
        }

        if (timeout !== 0) {
            $("#log-container").append(`休眠 ${timeout} 秒.\n`);
        }
        // Wait timeout and pass next archive
        setTimeout(() => {
            const command = commandBase;
            command.archive = arcs.splice(0, 1)[0];
            // eslint-disable-next-line no-console
            console.log(command);
            Batch.socket.send(JSON.stringify(command));
        }, timeout * 1000);
    };

    Batch.socket.onerror = Batch.batchError;
    Batch.socket.onclose = Batch.endBatch;
};

/**
 * On websocket message, update the UI to show the archive currently being treated
 * @param {*} event The websocket message
 */
Batch.updateBatchStatus = function (event) {
    const msg = JSON.parse(event.data);

    if (msg.success === 0) {
        $("#log-container").append(`处理 ID ${msg.id} (${msg.message})时发生插件错误\n\n`);
    } else {
        switch (Batch.currentOperation) {
        case "plugin":
            $("#log-container").append(`处理 ID ${msg.id}  "${Batch.currentPlugin}" (添加标签: ${msg.tags})\n\n`);
            break;
        case "delete":
            $("#log-container").append(`删除 ID ${msg.id} (文件名: ${msg.filename})\n\n`);
            break;
        case "tagrules":
            $("#log-container").append(`修改 ID ${msg.id} (新标签: ${msg.tags})\n\n`);
            break;
        case "clearnew": {
            $("#log-container").append(`清除了NEW标志 ID ${msg.id}\n\n`);
            // Remove last character from matching row
            const t = $(`#${msg.id}`).next().text().replace("🆕", "");
            $(`#${msg.id}`).next().text(t);
            break;
        }
        default:
            $("#log-container").append(`未知操作 ${Batch.currentOperation} (${msg.message})\n\n`);
            break;
        }

        // Uncheck ID in list
        $(`#${msg.id}`)[0].checked = false;

        if (msg.title !== undefined && msg.title !== "") {
            $("#log-container").append(`修改标题为: ${msg.title}\n`);
        }
    }

    // Update counts
    Batch.treatedArchives += 1;

    const percentage = Batch.treatedArchives / Batch.totalArchives;
    $(".bar").attr("style", `width: ${percentage * 100}%;`);
    $("#arcs").html(Batch.treatedArchives);

    Batch.scrollLogs();
};

/**
 * Handle websocket errors.
 */
Batch.batchError = function () {
    $("#log-container").append("************\n错误！ 终止会话。\n");
    Batch.scrollLogs();

    $.toast({
        showHideTransition: "slide",
        position: "top-left",
        loader: false,
        hideAfter: false,
        heading: "在批量添加标签时出错！",
        text: "请检查错误日志。",
        icon: "error",
    });
};

/**
 * Handle WS connection close events.
 * @param {*} event The closing event
 */
Batch.endBatch = function (event) {
    let status = "info";

    if (event.code === 1001) { status = "warning"; }

    $("#log-container").append(`************\n${event.reason}(code ${event.code})\n`);
    Batch.scrollLogs();

    $.toast({
        showHideTransition: "slide",
        position: "top-left",
        loader: false,
        heading: "批量添加标签完成！",
        text: "",
        icon: status,
    });

    // Delete the search cache after a finished session
    Server.callAPI("api/search/cache", "DELETE", null, "删除缓存时出错！ 请检查日志。", null);

    $("#cancel-job").hide();

    if (Batch.currentOperation === "delete") {
        $("#log-container").append("已删除该档案，将在 5 秒内重新加载页面...\n");
        setTimeout(() => { window.location.reload(); }, 5000);
    } else {
        $("#restart-job").show();
    }
};

Batch.checkAll = function () {
    const btn = $("#check-uncheck")[0];

    $(".checklist > * > input:checkbox").prop("checked", btn.checked);
    btn.checked = !btn.checked;
};

Batch.scrollLogs = function () {
    $("#log-container").scrollTop($("#log-container").prop("scrollHeight"));
};

Batch.cancelBatch = function () {
    $("#log-container").append("Cancelling...\n");
    Batch.socket.close();
};

Batch.restartBatchUI = function () {
    $(".tag-options").show();
    $(".job-status").hide();
};

$(document).ready(() => {
    Batch.initializeAll();
});

window.Batch = Batch;
