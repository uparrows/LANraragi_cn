/**
 * Functions for Generic API calls.
 */
const Server = {};

Server.isScriptRunning = false;

/**
 * Call that shows a popup to the user on success/failure.
 * Returns the promise so you can add final callbacks if needed.
 * @param {*} endpoint URL endpoint
 * @param {*} method GET/PUT/DELETE/POST
 * @param {*} successMessage Message written in the toast if request succeeded (success = 1)
 * @param {*} errorMessage Header of the error message if request fails (success = 0)
 * @param {*} successCallback called if request succeeded
 * @returns The result of the callback, or NULL.
 */
Server.callAPI = function (endpoint, method, successMessage, errorMessage, successCallback) {
    return fetch(endpoint, { method })
        .then((response) => (response.ok ? response.json() : { success: 0, error: "响应不正确" }))
        .then((data) => {
            if (Object.prototype.hasOwnProperty.call(data, "success") && !data.success) {
                throw new Error(data.error);
            } else {
                if (successMessage !== null) {
                    LRR.toast({
                        heading: successMessage,
                        icon: "success",
                        hideAfter: 7000,
                    });
                }

                if (successCallback !== null) return successCallback(data);

                return null;
            }
        })
        .catch((error) => LRR.showErrorToast(errorMessage, error));
};

/**
 * Check the status of a Minion job until it's completed.
 * @param {*} jobId Job ID to check
 * @param {*} useDetail Whether to get full details or the job or not.
 *            This requires the user to be logged in.
 * @param {*} callback Execute a callback on successful job completion.
 * @param {*} failureCallback Execute a callback on unsuccessful job completion.
 */
Server.checkJobStatus = function (jobId, useDetail, callback, failureCallback) {
    fetch(useDetail ? `/api/minion/${jobId}/detail` : `/api/minion/${jobId}`, { method: "GET" })
        .then((response) => (response.ok ? response.json() : { success: 0, error: "响应不正确" }))
        .then((data) => {
            if (data.error) throw new Error(data.error);

            if (data.state === "failed") {
                throw new Error(data.result);
            }

            if (data.state !== "finished") {
                // Wait and retry, job isn't done yet
                setTimeout(() => {
                    Server.checkJobStatus(jobId, useDetail, callback, failureCallback);
                }, 1000);
            } else {
                // Update UI with info
                callback(data);
            }
        })
        .catch((error) => { LRR.showErrorToast("检查Minion工作状态时出错", error); failureCallback(error); });
};

/**
 * POSTs the data of the specified form to the page.
 * This is used for Edit, Config and Plugins.
 * @param {*} formSelector The form to POST
 * @returns the promise object so you can chain more callbacks.
 */
Server.saveFormData = function (formSelector) {
    const postData = new FormData($(formSelector)[0]);

    return fetch(window.location.href, { method: "POST", body: postData })
        .then((response) => (response.ok ? response.json() : { success: 0, error: "响应不正确" }))
        .then((data) => {
            if (data.success) {
                LRR.toast({
                    heading: "保存成功!",
                    icon: "success",
                });
            } else {
                throw new Error(data.message);
            }
        })
        .catch((error) => LRR.showErrorToast("保存出错", error));
};

Server.triggerScript = function (namespace) {
    const scriptArg = $(`#${namespace}_ARG`).val();

    if (Server.isScriptRunning) {
        LRR.showErrorToast("一个脚本已在运行.", "请等待它终止.");
        return;
    }

    Server.isScriptRunning = true;
    $(".script-running").show();
    $(".stdbtn").hide();

    // Save data before triggering script
    Server.saveFormData("#editPluginForm")
        .then(Server.callAPI(`/api/plugins/queue?plugin=${namespace}&arg=${scriptArg}`, "POST", null, "执行脚本时出错 :",
            (data) => {
                // Check minion job state periodically while we're on this page
                Server.checkJobStatus(
                    data.job,
                    true,
                    (d) => {
                        Server.isScriptRunning = false;
                        $(".script-running").hide();
                        $(".stdbtn").show();

                        if (d.result.success === 1) {
                            LRR.toast({
                                heading: "脚本效果",
                                text: `<pre>${JSON.stringify(d.result.data, null, 4)}</pre>`,
                                icon: "info",
                                hideAfter: 10000,
                                closeOnClick: false,
                                draggable: false,
                            });
                        } else LRR.showErrorToast(`Script failed: ${d.result.error}`);
                    },
                    () => {
                        Server.isScriptRunning = false;
                        $(".script-running").hide();
                        $(".stdbtn").show();
                    },
                );
            },
        ));
};

Server.cleanTemporaryFolder = function () {
    Server.callAPI("/api/tempfolder", "DELETE", "临时文件夹已清理！", "清理临时文件夹时出错 :",
        (data) => {
            $("#tempsize").html(data.newsize);
        },
    );
};

Server.invalidateCache = function () {
    Server.callAPI("/api/search/cache", "DELETE", "丢弃搜索缓存!", "删除缓存时出错！ 请检查日志.", null);
};

Server.clearAllNewFlags = function () {
    Server.callAPI("/api/database/isnew", "DELETE", "所有档案都不再是新的！", "清理NEW标签时出错！ 请检查日志.", null);
};

Server.dropDatabase = function () {
    LRR.showPopUp({
        title: "这是一个（非常）破坏性的操作! ",
        text: "您确定要擦除数据库吗?",
        icon: "warning",
        showCancelButton: true,
        focusConfirm: false,
        confirmButtonText: "是的，这样做!",
        reverseButtons: true,
        confirmButtonColor: "#d33",
    }).then((result) => {
        if (result.isConfirmed) {
            Server.callAPI("/api/database/drop", "POST", "再见! 重定向...", "重置数据库时出错？ 请检查日志.",
                () => {
                    setTimeout(() => { document.location.href = "./"; }, 1500);
                },
            );
        }
    });
};

Server.cleanDatabase = function () {
    Server.callAPI("/api/database/clean", "POST", null, "清理数据库时出错！ 请检查日志.",
        (data) => {
            LRR.toast({
                heading: `成功清理数据库并删除 ${data.deleted} 条!`,
                icon: "success",
                hideAfter: 7000,
            });

            if (data.unlinked > 0) {
                LRR.toast({
                    heading: `${data.unlinked} 其他条目已从数据库中取消链接，将在下次清理时删除!`,
                    text: "如果某些文件从存档索引中消失，请立即进行备份.",
                    icon: "warning",
                    hideAfter: 16000,
                });
            }
        },
    );
};

Server.regenerateThumbnails = function (force) {
    const forceparam = force ? 1 : 0;
    Server.callAPI(`/api/regen_thumbs?force=${forceparam}`, "POST",
        "正在排队处理重新生成缩略图工作! 请继续关注更新或检查 Minion 控制台.",
        "向 Minion 发送作业时出错:",
        (data) => {
            // Disable the buttons to avoid accidental double-clicks.
            $("#genthumb-button").prop("disabled", true);
            $("#forcethumb-button").prop("disabled", true);

            // Check minion job state periodically while we're on this page
            Server.checkJobStatus(
                data.job,
                true,
                (d) => {
                    $("#genthumb-button").prop("disabled", false);
                    $("#forcethumb-button").prop("disabled", false);
                    LRR.toast({
                        heading: "所有缩略图生成！ 但遇到以下错误:",
                        text: d.result.errors,
                        icon: "success",
                        hideAfter: 15000,
                        closeOnClick: false,
                        draggable: false,
                    });
                },
                (error) => {
                    $("#genthumb-button").prop("disabled", false);
                    $("#forcethumb-button").prop("disabled", false);
                    LRR.showErrorToast("缩略图重建失败!", error);
                },
            );
        },
    );
};

// Adds an archive to a category. Basic implementation to use everywhere.
Server.addArchiveToCategory = function (arcId, catId) {
    Server.callAPI(`/api/categories/${catId}/${arcId}`, "PUT", `添加 ${arcId}到${catId}!`, "将档案添加/移除到类别时出错", null);
};

// Ditto, but for removing.
Server.removeArchiveFromCategory = function (arcId, catId) {
    Server.callAPI(`/api/categories/${catId}/${arcId}`, "DELETE", `从${catId}移除${arcId}!`, "将档案添加/移除到类别时出错", null);
};

/**
 * Sends a DELETE request for that archive ID,
 * deleting the Redis key and attempting to delete the archive file.
 * @param {*} arcId Archive ID
 * @param {*} callback Callback to execute once the archive is deleted (usually a redirection)
 */
Server.deleteArchive = function (arcId, callback) {
    fetch(`/api/archives/${arcId}`, { method: "DELETE" })
        .then((response) => (response.ok ? response.json() : { success: 0, error: "响应不正确" }))
        .then((data) => {
            if (data.success === "0") {
                LRR.toast({
                    heading: "无法删除存档文件. <br> (或许已被删除?)",
                    text: "存档元数据已完整删除. <br> 请在返资源库之前手动删除文件.",
                    icon: "warning",
                    hideAfter: 20000,
                });
                $(".stdbtn").hide();
                $("#goback").show();
            } else {
                LRR.toast({
                    heading: "存档已成功删除，重定向 ...",
                    text: `File name : ${data.filename}`,
                    icon: "success",
                    hideAfter: 7000,
                });
                setTimeout(callback, 1500);
            }
        })
        .catch((error) => LRR.showErrorToast("删除存档时出错", error));
};
