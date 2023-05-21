const JENKINS_BASE = "http://172.17.0.2:80"
const typeJsonHeaders = { "Content-Type": "application/json"}

interface IJenkinsContext {
    jobID: string,
    buildID: string
}

const prefix = (ctx: IJenkinsContext)=> `/job/${ctx.jobID}/${ctx.buildID}`

const KNOWN_API = {
    consoleText: (ctx:IJenkinsContext) => 
        JENKINS_BASE + prefix(ctx) + "/consoleText",

    // WF = WorkFlow
    wfAPIMain: (ctx:IJenkinsContext) => 
        JENKINS_BASE + prefix(ctx) + "/wfapi/describe",
}

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

export type StatusResult = "IN_PROGRESS" | "SUCCESS" | "FAILURE" |
    "ABORTED" | "NOT_BUILT" | "UNSTABLE" | "PENDING"

//schema using this tool:
//  https://transform.tools/json-to-typescript

export type WfApiMainResult = {
    _links: {
      self: {
        href: string // Relative to JENKINS_BASE
      }
    }
    id: string
    name: string
    status: StatusResult
    startTimeMillis: number
    endTimeMillis: number
    durationMillis: number
    queueDurationMillis: number
    pauseDurationMillis: number
    stages: Array<{
      _links: {
        self: {
          href: string // Relative to JENKINS_BASE
        }
      }
      id: string
      name: string
      execNode: string // in docker: ""
      status: StatusResult,
      startTimeMillis: number
      durationMillis: number
      pauseDurationMillis: number
    }>
}

export type WfApiStageResult = {
    _links: {
      self: {
        href: string // Relative to JENKINS_BASE
      }
    }
    id: string
    name: string
    execNode: string
    status: StatusResult
    startTimeMillis: number
    durationMillis: number
    pauseDurationMillis: number
    stageFlowNodes: Array<{ // == "child nodes", all nodes from now on
      _links: {
        self: {
          href: string // Relative to JENKINS_BASE
        }
        
        // Stages like "parallel" not always have log/console
        log?: {
          href: string // Relative to JENKINS_BASE
        }
        console?: {
          href: string // Relative to JENKINS_BASE
        }
      }
      id: string
      name: string
      execNode: string // in docker: ""
      status: StatusResult
      parameterDescription: string
      startTimeMillis: number
      durationMillis: number
      pauseDurationMillis: number
      parentNodes: Array<string>
    }>
  }

const getFullConsoleText = async (ctx: IJenkinsContext) =>
    await _fetchTxt(KNOWN_API.consoleText(ctx))

const WfMainDescribe = async (ctx: IJenkinsContext) : Promise<WfApiMainResult> => 
    await JSON.parse( await _fetchTxt(KNOWN_API.wfAPIMain(ctx)) || "{}")

const WfStageDescribe = async (ctx: IJenkinsContext, relPath: string) : Promise<WfApiStageResult> => 
    await JSON.parse( await _fetchTxt(relPath) || "{}")

let _ctx: IJenkinsContext = {buildID:"1", jobID:"job"}
console.log("Start...");
//console.log(await getFullConsoleText(_ctx));
console.log(JSON.stringify(await WfMainDescribe(_ctx),null,4));
console.log('---------------XXXXXXXXXXXXXXXXXXX')
for (let index = 13; index < 19; index++) {
    try {
        console.log(JSON.stringify(await WfStageDescribe(_ctx,JENKINS_BASE + "/job/job/1/execution/node/" + index +"/wfapi/describe"),null,4));
    } catch (error) {
        console.log("NOT FOUND FOR - " + index)
    }
}

