package mode

// function getMemberGrades(Target target,address member) external view returns(uint256);
type Grades struct {
	Target string `json:"target"`
	Member string `json:"member"`
}

// function multiGetMemberGrades(Target target,address[] memory member) external view returns(Assemble[] memory);
type MultiGrades struct {
	Target  string   `json:"target"`
	Members []string `json:"members"`
}

// function distributeRankings(address[] memory members,Target target,string memory mark) external;
type Reward struct {
	Members []string `json:"members"`
	Target  string   `json:"target"`
	Mark    string   `json:"mark"`
}
