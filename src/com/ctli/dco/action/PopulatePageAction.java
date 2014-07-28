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
	
	int compCount = 0;

	int pendingCount = 0;
	
	



	public int getCompCount() {
		return compCount;
	}

	public void setCompCount(int compCount) {
		this.compCount = compCount;
	}

	public int getPendingCount() {
		return pendingCount;
	}

	public void setPendingCount(int pendingCount) {
		this.pendingCount = pendingCount;
	}

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

	@SuppressWarnings("unchecked")
	public String getIssues() throws Exception {
		issueList = new ArrayList<Issue>();
		IPopulatePageService ppService = new PopulatePageService();
		try{
		ArrayList<Object> returnList = ppService.getIssueList();	
		issueList = (ArrayList<Issue>) returnList.get(0);
		int countArray[] = (int []) returnList.get(1);
		compCount = (int) (countArray[0]*100/(countArray[0] + countArray[1]));
		pendingCount = (int) (countArray[1]*100/(countArray[0] + countArray[1]));
		}
		catch(Exception e){
			issueList = null;
			compCount = 0 ;
			pendingCount = 0;
			System.out.println(e.getMessage());
		}
		getIssuesCallCount++;

		return "success";
	}

	/*
	 * public static void main(String[] args) { UploadScriptAction ul = new
	 * UploadScriptAction(); ul.combineScripts("flatfiles"); }
	 */

}
