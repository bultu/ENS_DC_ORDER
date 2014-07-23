package com.ctli.dco.action;

import com.ctli.dco.service.IGenerateScriptService;
import com.ctli.dco.service.impl.GenerateScriptService;
import com.opensymphony.xwork2.ActionSupport;

public class GenerateScriptAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	String developerName;
	String fileName;
	String date;
	String type;
	String resultsFile;

	public String getDeveloperName() {
		return developerName;
	}

	public void setDeveloperName(String developerName) {
		this.developerName = developerName;
	}

	public String getFileName() {
		return fileName;
	}

	public void setFileName(String fileName) {
		this.fileName = fileName;
	}

	public String getDate() {
		return date;
	}

	public void setDate(String date) {
		this.date = date;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getResultsFile() {
		return resultsFile;
	}

	public void setResultsFile(String resultsFile) {
		this.resultsFile = resultsFile;
	}

	@Override
	public String execute() throws Exception {
		IGenerateScriptService gsService = new GenerateScriptService();

		gsService.generateScript(developerName, fileName, date, type);
		// uploadScript(scriptPath);

		return "success";
	}

}
