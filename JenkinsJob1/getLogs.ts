const JENKINS_BASE = "http://172.17.0.2:80"

const typeJsonHeaders = { "Content-Type": "application/json"}

async function _fetchTxt(url, method="GET", headers=undefined, body=undefined) : Promise< string | false> {
    try {
        let r = await fetch(url,{method, headers, body});
        let j = await r.text();
        return j;
    } catch (error) {
        console.log("[FETCH-ERR]",error);
        return false;
    }
}

async function getFullConsoleText() {
    let url = JENKINS_BASE + "/job/job/1/consoleText";
    let result = await _fetchTxt(url);
    return result;    
}

console.log("Start...");
console.log(await getFullConsoleText());
