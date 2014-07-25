package com.ctli.dco.action;

import java.util.ArrayList;

import com.ctli.dco.dto.FolderContent;
import com.ctli.dco.dto.Issue;
import com.ctli.dco.service.IPopulatePageService;
import com.ctli.dco.service.impl.PopulatePageService;
import com.opensymphony.xwork2.ActionSupport;

public class PopulatePageAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	ArrayList<FolderContent> foldercontents = null;
	ArrayList<Issue> issueList = null;
	int getIssuesCallCount = 0;

	public ArrayList<Issue> getIssueList() {
		return issueList;
	}

	public void setIssueList(ArrayList<Issue> issueList) {
		this.issueList = issueList;
	}

	public int getGetIssuesCallCount() {
		return getIssuesCallCount;
	}

	public void setGetIssuesCallCount(int getIssuesCallCount) {
		this.getIssuesCallCount = getIssuesCallCount;
	}

	public ArrayList<FolderContent> getFoldercontents() {
		return foldercontents;
	}

	public void setFoldercontents(ArrayList<FolderContent> foldercontents) {
		this.foldercontents = foldercontents;
	}

	@Override
	public String execute() throws Exception {
		foldercontents = new ArrayList<FolderContent>();
		IPopulatePageService ppService = new PopulatePageService();
		foldercontents = ppService.populatePage();
		getIssuesCallCount++;
		return "success";
	}

	public String getIssues() throws Exception {
		issueList = new ArrayList<Issue>();
		IPopulatePageService ppService = new PopulatePageService();
		issueList = ppService.getIssueList();
		getIssuesCallCount++;

		return "success";
	}

	/*
	 * public static void main(String[] args) { UploadScriptAction ul = new
	 * UploadScriptAction(); ul.combineScripts("flatfiles"); }
	 */

}
