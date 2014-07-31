package com.ctli.dco.action;

import com.ctli.dco.service.impl.UploadScriptService;
import com.opensymphony.xwork2.ActionSupport;

public class UploadScriptAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	String fileToUpload;
	String status;

	public String getFileToUpload() {
		return fileToUpload;
	}

	public void setFileToUpload(String fileToUpload) {
		this.fileToUpload = fileToUpload;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	@Override
	public String execute() throws Exception {
		UploadScriptService usService = new UploadScriptService();
		try{
		status = usService.uploadScript(fileToUpload.split("/")[0] , fileToUpload.split("/")[1]);
		} catch(Exception e){
			System.out.println(e.getMessage());
			status = "Failed to upload script at remote server";
		}

		return "success";
	}

	/*
	 * public static void main(String[] args) { UploadScriptAction ul = new
	 * UploadScriptAction(); ul.combineScripts("flatfiles"); }
	 */

}
