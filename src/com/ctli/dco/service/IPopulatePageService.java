package com.ctli.dco.service;

import java.util.ArrayList;

import com.ctli.dco.dto.FolderContent;

public interface IPopulatePageService {

	public ArrayList<FolderContent> populatePage();

	public ArrayList<Object> getIssueList();

}
