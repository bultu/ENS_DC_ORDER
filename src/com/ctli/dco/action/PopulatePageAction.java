package com.ctli.dco.action;

import java.util.ArrayList;

import com.ctli.dco.dto.FolderContent;
import com.ctli.dco.service.IPopulatePageService;
import com.ctli.dco.service.impl.PopulatePageService;
import com.opensymphony.xwork2.ActionSupport;

public class PopulatePageAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	ArrayList<FolderContent> foldercontents = new ArrayList<FolderContent>();

	public ArrayList<FolderContent> getFoldercontents() {
		return foldercontents;
	}

	public void setFoldercontents(ArrayList<FolderContent> foldercontents) {
		this.foldercontents = foldercontents;
	}

	@Override
	public String execute() throws Exception {
		IPopulatePageService ppService = new PopulatePageService();
		foldercontents = ppService.populatePage();

		return "success";
	}

	/*
	 * public static void main(String[] args) { UploadScriptAction ul = new
	 * UploadScriptAction(); ul.combineScripts("flatfiles"); }
	 */

}
