package com.ctli.dco.service.impl;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;

import com.ctli.dco.dto.Developer;
import com.ctli.dco.dto.FolderContent;
import com.ctli.dco.dto.Issue;
import com.ctli.dco.service.IPopulatePageService;

public class PopulatePageService implements IPopulatePageService {

	@Override
	public ArrayList<FolderContent> populatePage() {

		return listDirectory("combinedScript");
	}

	/*
	 * public static void main(String[] args) { PopulatePageService pss = new
	 * PopulatePageService(); pss.listDirectory("combinedScript"); }
	 */
	ArrayList<FolderContent> listDirectory(String directoryPath) {
		ArrayList<FolderContent> foldercontents = new ArrayList<FolderContent>();

		File combinedScriptFolder = new File(directoryPath);
		File[] listOfRefFiles = combinedScriptFolder.listFiles();

		if (listOfRefFiles == null)
			listOfRefFiles = new File[0];

		for (int i = 0; i < listOfRefFiles.length; i++) {
			File directory = listOfRefFiles[i];
			FolderContent folderContent = new FolderContent();

			if (directory.isDirectory()) {
				foldercontents
						.addAll(listDirectory(directory.getAbsolutePath()));
			} else if (directory.isFile()) {

				BufferedReader temp = null;
				FileReader tempFileReader = null;
				try {
					tempFileReader = new FileReader(directory);
					temp = new BufferedReader(tempFileReader);
					String line;
					while ((line = temp.readLine()) != null
							&& folderContent.isNotPopulated()) {
						if (line.contains("-- AUTHOR:"))
							folderContent.setCreatedBy(line.split(":")[1]
									.replace(" ", ""));
						if (line.contains("-- DATE:"))
							folderContent.setCreationDate(line.split(":")[1]
									.replace(" ", ""));
						folderContent.setType(directoryPath.substring(
								directoryPath.lastIndexOf("\\") + 1,
								directoryPath.length()));

					}

				} catch (IOException e) {
					System.out.println(e.getMessage());
				} finally {
					try {
						tempFileReader.close();
						temp.close();
					} catch (IOException e) {
						System.out.println(e.getMessage());
					}
				}

				folderContent.setFileName(directory.getName());
				foldercontents.add(folderContent);
			}

		}

		return foldercontents;

	}

	@Override
	public ArrayList<Issue> getIssueList() {
		ArrayList<Issue> issueList = new ArrayList<Issue>();
		ArrayList<Developer> devList = new ArrayList<Developer>();
		String issuedirectory = "inputFiles/DC_ORDER/output/filteredData.txt";
		String devDirectory = "referenceData/DC_ORDER/DeveloperList.txt";

		BufferedReader issueBuffer = null;
		FileReader issueFileReader = null;

		BufferedReader devBuffer = null;
		FileReader devFileReader = null;
		try {

			// Populate devList from flatfile in devDirectory
			
			devFileReader = new FileReader(devDirectory);
			devBuffer = new BufferedReader(devFileReader);
			String line;
			while ((line = devBuffer.readLine()) != null) {
				Developer dev = new Developer();
				dev.setName(line.split("--")[0]);
				dev.setThreshold(Integer.parseInt(line.split("--")[1]));
				devList.add(dev);
			}

			// Assign DC_ORDER Issues to developers

			issueFileReader = new FileReader(issuedirectory);
			issueBuffer = new BufferedReader(issueFileReader);
			int id = 1;
			while ((line = issueBuffer.readLine()) != null) {
				Issue issue = new Issue();
				issue.setIssueID(id++);
				issue.setStatus("Assigned");
				issue.setTitle(line);
				issueList.add(issue);
			}

			int index = 0;
			Developer devItem = devList.get(index);
			int devIssueLimit = devItem.getThreshold();

			for (Issue issueItem : issueList) {
				if (devIssueLimit > 0) {
					issueItem.setDeveloperName(devItem.getName());
					devIssueLimit--;
				} else {
					devItem = devList.get(++index);
					devIssueLimit = devItem.getThreshold();
					issueItem.setDeveloperName(devItem.getName());
					devIssueLimit--;
				}
			}

		} catch (IOException | IndexOutOfBoundsException e) {
			System.out.println(e.getMessage());
		} finally {
			try {
				devFileReader.close();
				devBuffer.close();
				issueFileReader.close();
				issueBuffer.close();
			} catch (IOException e) {
				System.out.println(e.getMessage());
			}
		}
		return issueList;
	}

}
