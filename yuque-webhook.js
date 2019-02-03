const http = require("http");
const { spawn } = require("child_process");

var listenAddress;
var port;
var autoDeploy;

if (process.env.YUQUE_WEBHOOK_PORT !== undefined) {
    port = Number(process.env.YUQUE_WEBHOOK_PORT);
} else {
    port = 32125;
}

if (process.env.YUQUE_WEBHOOK_LISTENADDR !== undefined) {
    listenAddress = process.env.YUQUE_WEBHOOK_LISTENADDR;
} else {
    listenAddress = "0.0.0.0";
}

if (process.env.YUQUE_WEBHOOK_AUTODEPLOY !== undefined) {
    autoDeploy = Boolean(Number(process.env.YUQUE_WEBHOOK_AUTODEPLOY));
} else {
    autoDeploy = false;
}

var syncDo = autoDeploy ? 'sync-gen-deploy' : 'sync-gen';

var server = http.createServer();
server.on("request", (req, res) => {
    server.getConnections( (err, count) => {
        if (err) {
            res.writeHead(400, {
                "Content-Type": "application/json"
            });
            res.end(JSON.stringify({"status": 400, "msg": "Server error."}));
            console.error(`server.getConnections() Error.`);
            return;
        }
        else if (count > 1) {
            res.writeHead(503, {
                "Content-Type": "application/json"
            });
            res.end(JSON.stringify({"status": 503, "msg": "Busy. Try again later."}));
            console.log(`Request received, but server is busy now. (${count})`);
            return;
        }

        console.log(`Request received. Now run ${syncDo}...`);
        const syncProc = spawn('npm', ['--prefix=/blog', 'run', syncDo]);
        let outStringChunks = [];
        let errStringChunks = [];
        syncProc.stdout.on("data", (data) => {
            process.stdout.write(`Stdout: ${data}`);
            outStringChunks.push(data);
        });
        syncProc.stderr.on("data", (data) => {
            process.stderr.write(`Stderr: ${data}`);
            errStringChunks.push(data);
        });
        syncProc.on("close", (code) => {
            console.log(`Child process exited with code ${code}`);
            if (code === 0) {
                let bodyString = JSON.stringify({"status": 200, "msg": "Action completed successfully.", "stdout": outStringChunks.join(""), "stderr": errStringChunks.join("")});
                res.writeHead(200, {
                    "Content-Type": "application/json"
                });
                res.end(bodyString);
                console.log('Respond with "success"');
            } else {
                let bodyString = JSON.stringify({"status": 400, "msg": "Error encountered.", "stdout": outStringChunks.join(""), "stderr": errStringChunks.join("")});
                res.writeHead(400, {
                    "Content-Type": "application/json"
                });
                res.end(bodyString);
                console.log('Respond with "error"');
            }
        });
        req.on("error", err => {
            console.err("Request error", err);
            let bodyString = JSON.stringify({"status": 400, "msg": "Error encountered."});
            res.writeHead(400, {
                 "Content-Type": "application/json"
            });
            res.end(bodyString);
        });
        res.on("error", err => {
            console.err("Response error", err);
        });
    });
});

server.listen(port, listenAddress, () => {
    console.log(`Server listening at ${server.address().address}:${server.address().port}`);
});

