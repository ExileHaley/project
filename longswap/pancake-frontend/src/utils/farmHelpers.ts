//pid从139开始
const ARCHIVED_FARMS_START_PID = 139
//pid到250结束
const ARCHIVED_FARMS_END_PID = 250

const isArchivedPid = (pid: number) => pid >= ARCHIVED_FARMS_START_PID && pid <= ARCHIVED_FARMS_END_PID

export default isArchivedPid
