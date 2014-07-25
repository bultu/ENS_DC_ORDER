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
		/* BufferedReader scriptTemplatePart1 = null; */

		File oldYesterday = new File("inputFiles/" + type
				+ "/input/yesterday.txt");
		File source1 = new File("inputFiles/" + type + "/input/today.txt");
		File dest1 = new File("inputFiles/" + type + "/input/yesterday.txt");
		File source = new File("inputFiles/" + type + "/new/results.txt");
		File dest = new File("inputFiles/" + type + "/input/today.txt");
		File automatedIssues = new File("flatFiles/" + type
				+ "/aaautomatedIssues.txt");
		// File automatedIssuesDirectory = new File("flatFiles/"+type);
		File resultsInputFile = new File(resultsFile);

		try {

			System.out
					.println("*****************DC Order Script Generator Tool*****************");

			String sCurrentLineOld;
			String sCurrentLineNew;
			String sPart1;

			try {

				copyFile(resultsInputFile, source);
				deleteFile(oldYesterday);
				moveFile(source1, dest1);
				copyFile(source, dest);

				// FileUtils.cleanDirectory(automatedIssuesDirectory);

				brOld = new BufferedReader(new FileReader("inputFiles/" + type
						+ "/input/yesterday.txt"));
				brNew = new BufferedReader(new FileReader("inputFiles/" + type
						+ "/input/today.txt"));
				/*
				 * scriptTemplatePart1 = new BufferedReader(new FileReader(
				 * "referenceData/DC_ORDER/CSM_CUP1_DC_ORDERS_IR99999_part1.txt"
				 * ));
				 */
			} catch (Exception e) {
				System.out.println("Input Files missing , Please read Note.");
				System.out.println("NOTE: Place results.txt in new directory");
				System.out
						.println("NOTE: Place CSM_CUP1_DC_ORDERS_IR99999_part1.txt in   referenceData/DC_ORDER/");
				System.out
						.println("----------------------------------------------------------------");
				System.exit(0);
			}

			/*
			 * scriptTemplatePart2 = new BufferedReader(new FileReader(
			 * "template/CSM_CUP1_DC_ORDERS_IR99999_part2.txt"));
			 */

			File commonData = new File("inputFiles/" + type
					+ "/output/commonData.txt");
			File filteredData = new File("inputFiles/" + type
					+ "/output/filteredData.txt");

			/*
			 * File DcOrderscript = new File("combinedScript/" + type + "/" +
			 * fileName + ".sql");
			 */

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

			/*
			 * DcOrderscript.createNewFile(); FileWriter DcOrderScriptWriter =
			 * new FileWriter( DcOrderscript.getAbsoluteFile());
			 * 
			 * BufferedWriter DcOrderScriptBuffer = new BufferedWriter(
			 * DcOrderScriptWriter);
			 */

			/*
			 * while ((sPart1 = scriptTemplatePart1.readLine()) != null) {
			 * DcOrderScriptBuffer.write(sPart1);
			 * DcOrderScriptBuffer.write('\n'); }
			 */

			for (String filteredDataRow : newFileDataArrayList) {
				filteredDataBuffer.write(filteredDataRow);
				filteredDataBuffer.write('\n');
				/*
				 * DcOrderScriptBuffer.write(filteredDataRow);
				 * DcOrderScriptBuffer.write('\n');
				 */

			}

			/*
			 * DcOrderScriptBuffer.write("END;\n");
			 * DcOrderScriptBuffer.write("/");
			 */

			System.out.println("Done");

			System.out.println("----Files Generated----");
			System.out.println("aautomatedIssues.txt");
			System.out.println("commonData.txt");
			System.out.println("filteredData.txt");
			System.out
					.println("----------------------------------------------------------------");
			assignIssues();
			commonDataBuffer.close();
			filteredDataBuffer.close();
			/* DcOrderScriptBuffer.close(); */

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
	


	public ArrayList<Issue> assignIssues() {
		ArrayList<Issue> issueList = new ArrayList<Issue>();
		ArrayList<Developer> devList = new ArrayList<Developer>();
		String issuedirectory = "inputFiles/DC_ORDER/output/filteredData.txt";
		String devDirectory = "referenceData/DC_ORDER/DeveloperList.txt";

		FileWriter filteredDataWriter = null;
		BufferedWriter filteredDataBuffer = null;

		BufferedReader issueBuffer = null;
		FileReader issueFileReader = null;

		BufferedReader devBuffer = null;
		FileReader devFileReader = null;
		try {

			// Populate devList from flatfile in devDirectory

			filteredDataWriter = new FileWriter(issuedirectory);
			filteredDataBuffer = new BufferedWriter(filteredDataWriter);

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

			filteredDataWriter.close();
			filteredDataBuffer.close();

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
