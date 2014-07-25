package com.ctli.dco.service;

import java.util.ArrayList;

import com.ctli.dco.dto.FolderContent;
import com.ctli.dco.dto.Issue;

public interface IPopulatePageService {

	public ArrayList<FolderContent> populatePage();

	public ArrayList<Issue> getIssueList();

}
