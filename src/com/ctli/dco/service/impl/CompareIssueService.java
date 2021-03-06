package com.ctli.dco.service.impl;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.channels.FileChannel;
import java.util.ArrayList;

import com.ctli.dco.dto.Developer;
import com.ctli.dco.dto.Issue;
import com.ctli.dco.service.ICompareIssueService;

public class CompareIssueService implements ICompareIssueService {

	public void compareIssues(String type, String resultsFile) {

		BufferedReader brOld = null;
		BufferedReader brNew = null;

		File oldYesterday = new File("inputFiles/" + type
				+ "/input/yesterday.txt");
		File source1 = new File("inputFiles/" + type + "/input/today.txt");
		File dest1 = new File("inputFiles/" + type + "/input/yesterday.txt");
		File source = new File("inputFiles/" + type + "/new/results.txt");
		File dest = new File("inputFiles/" + type + "/input/today.txt");
		File automatedIssues = new File("flatFiles/" + type
				+ "/aaautomatedIssues.txt");
		File resultsInputFile = new File(resultsFile);

		try {

			System.out
					.println("*****************DC Order Script Generator Tool*****************");

			String sCurrentLineOld;
			String sCurrentLineNew;
			try {

				copyFile(resultsInputFile, source);
				deleteFile(oldYesterday);
				moveFile(source1, dest1);
				copyFile(source, dest);

				brOld = new BufferedReader(new FileReader("inputFiles/" + type
						+ "/input/yesterday.txt"));
				brNew = new BufferedReader(new FileReader("inputFiles/" + type
						+ "/input/today.txt"));
			} catch (Exception e) {
				System.out.println("Input Files missing , Please read Note.");
				System.out.println("NOTE: Place results.txt in new directory");
				System.out
						.println("NOTE: Place CSM_CUP1_DC_ORDERS_IR99999_part1.txt in   referenceData/DC_ORDER/");
				System.out
						.println("----------------------------------------------------------------");
				System.exit(0);
			}

			File commonData = new File("inputFiles/" + type
					+ "/output/commonData.txt");
			File filteredData = new File("inputFiles/" + type
					+ "/output/filteredData.txt");


			ArrayList<String> oldFileDataArrayList = new ArrayList<String>();
			ArrayList<String> newFileDataArrayList = new ArrayList<String>();
			ArrayList<String> commonFileDataArrayList = new ArrayList<String>();

			while ((sCurrentLineOld = brOld.readLine()) != null) {
				oldFileDataArrayList.add(sCurrentLineOld);
			}

			while ((sCurrentLineNew = brNew.readLine()) != null) {
				newFileDataArrayList.add(sCurrentLineNew);
			}

			for (String oldFileRow : oldFileDataArrayList) {
				if (newFileDataArrayList.contains(oldFileRow)) {
					commonFileDataArrayList.add(oldFileRow);
					newFileDataArrayList.remove(oldFileRow);
				}
			}

			commonData.createNewFile();
			filteredData.createNewFile();

			FileWriter commonDataWriter = new FileWriter(
					commonData.getAbsoluteFile());
			FileWriter filteredDataWriter = new FileWriter(
					filteredData.getAbsoluteFile());
			BufferedWriter commonDataBuffer = new BufferedWriter(
					commonDataWriter);
			BufferedWriter filteredDataBuffer = new BufferedWriter(
					filteredDataWriter);

			for (String commonDataRow : commonFileDataArrayList) {
				commonDataBuffer.write(commonDataRow);
				commonDataBuffer.write('\n');
			}

			for (String filteredDataRow : newFileDataArrayList) {
				filteredDataBuffer.write(filteredDataRow);
				filteredDataBuffer.write('\n');

			}

			System.out.println("Done");

			System.out.println("----Files Generated----");
			System.out.println("aautomatedIssues.txt");
			System.out.println("commonData.txt");
			System.out.println("filteredData.txt");
			System.out
					.println("----------------------------------------------------------------");
			
			commonDataBuffer.close();
			filteredDataBuffer.close();
			assignIssues();
			copyFile(filteredData, automatedIssues);
			
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				if (brOld != null)
					brOld.close();
				if (brNew != null)
					brNew.close();
			} catch (IOException ex) {
				ex.printStackTrace();
			}
		}

	}
	
/*	public static void main(String[] args) {
		CompareIssueService css = new  CompareIssueService();
		css.assignIssues();
	}*/


	public ArrayList<Issue> assignIssues() {
		ArrayList<Issue> issueList = new ArrayList<Issue>();
		ArrayList<Developer> devList = new ArrayList<Developer>();
		String issuedirectory = "inputFiles/DC_ORDER/output/commonData.txt";
		String devDirectory = "referenceData/DeveloperList.txt";


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

			try{
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
			}catch (IndexOutOfBoundsException e) {
				System.out.println(e.getMessage());
			}
			

			PrintWriter pw = new PrintWriter(issuedirectory);
			for (Issue issueItem : issueList) {
				pw.println(issueItem.getIssueID() + "--" + issueItem.getTitle()
						+ "--" + issueItem.getDeveloperName() + "--"
						+ issueItem.getStatus());
			}
			pw.close();

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

	public void copyFile(File source, File dest) {
		FileChannel inputChannel = null;
		FileChannel outputChannel = null;
		try {
			inputChannel = new FileInputStream(source).getChannel();
			outputChannel = new FileOutputStream(dest).getChannel();
			outputChannel.transferFrom(inputChannel, 0, inputChannel.size());
		} catch (IOException e) {
			System.out.println("Copy operation failed.");
			System.out.println(e.getMessage());
		} finally {
			try {
				System.out.println("Copied file : " + source.getAbsolutePath()
						+ " to " + dest.getAbsolutePath());
				inputChannel.close();
				outputChannel.close();
			} catch (IOException e) {
				System.out.println(e.getMessage());
			}
		}
	}

	public void moveFile(File source1, File dest1) {
		copyFile(source1, dest1);
		deleteFile(source1);

	}

	public void deleteFile(File source1) {
		if (source1.delete()) {
			System.out.println("Deleted File : " + source1.getAbsolutePath());
		} else {
			System.out.println("Delete operation failed.");
		}

	}

}
