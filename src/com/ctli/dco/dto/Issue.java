package com.ctli.dco.dto;

public class Issue {

	int issueID;
	String title;
	String developerName;
	String status;
	
	public int getIssueID() {
		return issueID;
	}
	public void setIssueID(int id) {
		this.issueID = id;
	}
	public String getTitle() {
		return title;
	}
	public void setTitle(String title) {
		this.title = title;
	}
	public String getDeveloperName() {
		return developerName;
	}
	public void setDeveloperName(String developerName) {
		this.developerName = developerName;
	}
	public String getStatus() {
		return status;
	}
	public void setStatus(String status) {
		this.status = status;
	}
	
	
}
