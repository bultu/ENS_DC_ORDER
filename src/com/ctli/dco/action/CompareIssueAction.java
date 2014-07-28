package com.ctli.dco.action;

import com.ctli.dco.service.ICompareIssueService;
import com.ctli.dco.service.impl.CompareIssueService;
import com.opensymphony.xwork2.ActionSupport;

public class CompareIssueAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	String filePath;
	String type;

	public String getFilePath() {
		return filePath;
	}

	public void setFilePath(String filePath) {
		this.filePath = filePath;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	@Override
	public String execute() throws Exception {
		ICompareIssueService ciService = new CompareIssueService();
		ciService.compareIssues(type, filePath);
		
		return "success";
	}

	/*
	 * public static void main(String[] args) { UploadScriptAction ul = new
	 * UploadScriptAction(); ul.combineScripts("flatfiles"); }
	 */

}
