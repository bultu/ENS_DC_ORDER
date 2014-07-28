package com.ctli.dco.action;

import com.ctli.dco.service.impl.SubmitScriptService;
import com.opensymphony.xwork2.ActionSupport;

@SuppressWarnings("serial")
public class SubmitScriptAction extends ActionSupport {

	String developerName;
	String issueDesc;
	String script;
	String type;
	
	

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getDeveloperName() {
		return developerName;
	}

	public void setDeveloperName(String developerName) {
		this.developerName = developerName;
	}

	public String getIssueDesc() {
		return issueDesc;
	}

	public void setIssueDesc(String issueDesc) {
		this.issueDesc = issueDesc;
	}

	public String getScript() {
		return script;
	}

	public void setScript(String script) {
		this.script = script;
	}

	@Override
	public String execute() throws Exception {
		SubmitScriptService ssService = new SubmitScriptService();
		
		ssService.makeScript(developerName, issueDesc, script, type);
		// uploadScript(scriptPath);

		return "success";
	}

	/*
	 * public static void main(String[] args) {
	 * 
	 * SubmitScriptAction ss = new SubmitScriptAction();
	 * ss.uploadScript("flatfiles/Anurag.txt"); }
	 */

}
