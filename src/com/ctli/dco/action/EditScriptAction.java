package com.ctli.dco.action;

import com.opensymphony.xwork2.ActionSupport;

public class EditScriptAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	String editScriptName;
	String script;
	String status;


	

	public String getScript() {
		return script;
	}

	public void setScript(String script) {
		this.script = script;
	}

	public String getEditScriptName() {
		return editScriptName;
	}

	public void setEditScriptName(String editScriptName) {
		this.editScriptName = editScriptName;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	@Override
	public String execute() throws Exception {
		//EditScriptService esService = new EditScriptService();
		//script = esService.editScript(editScriptName.split("/")[0] , editScriptName.split("/")[1]);
		script = "cdsdcnzxdkljcn";
		return "success";
	}

	/*
	 * public static void main(String[] args) { UploadScriptAction ul = new
	 * UploadScriptAction(); ul.combineScripts("flatfiles"); }
	 */

}
