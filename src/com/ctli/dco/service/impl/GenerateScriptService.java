package com.ctli.dco.service.impl;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import org.apache.commons.io.FileUtils;

import com.ctli.dco.service.IGenerateScriptService;

public class GenerateScriptService implements IGenerateScriptService {

	/*
	 * public static void main(String[] args) { GenerateScriptService gss = new
	 * GenerateScriptService(); gss.generateScript("Anurag", "baloo",
	 * "07/22/2014", "DC_ORDER"); gss.generateScript("adf", "baloo",
	 * "07/22/2014", "DC_ORDER"); gss.generateScript("asdx", "baloo",
	 * "07/22/2014", "DC_ORDER"); gss.generateScript("Anurag", "newFile",
	 * "07/22/2014", "DC_ORDER"); gss.generateScript("Prateek", "newFile",
	 * "07/22/2014", "DC_ORDER");
	 * 
	 * }
	 */
	@Override
	public void generateScript(String developerName, String fileName,
			String date, String type) {
		String scriptDirectory = "flatfiles/" + type;
		File automatedIssuesDirectory = new File(scriptDirectory);

		if (fileName.isEmpty() && type.equalsIgnoreCase("DC_ORDER"))
			fileName = "CSM_CUP1_DC_ORDERS_IR99999";

		if (fileName.isEmpty() && type.equalsIgnoreCase("CANCEL_ORDER"))
			fileName = "CSM_CUP1_CANCEL_ORDER_IR";

		String newFilePath = "combinedScript/" + type + "/" + fileName + ".sql";

		File combinedFile = new File(newFilePath);
		try {
			System.out
					.println("can write in file : " + combinedFile.canWrite());
			if (combinedFile.delete()) {
				System.out.println(combinedFile.getName() + " is deleted!");
			} else {
				System.out.println("Delete operation is failed.");
			}

			combinedFile.createNewFile();
		} catch (IOException e1) {
			System.out.println(e1.getMessage());
		}

		FileWriter DcOrderScriptWriter = null;
		// BufferedWriter DcOrderScriptBuffer = null;

		PrintWriter DcOrderScriptBuffer = null;

		// ICompareIssueService ciService = new CompareIssueService();
		// ciService.compareIssues(type, fileName, resultsFile);

		try {
			DcOrderScriptWriter = new FileWriter(combinedFile, true);
			DcOrderScriptBuffer = new PrintWriter(DcOrderScriptWriter);

			File folder = new File(scriptDirectory);
			File[] listOfFiles = folder.listFiles();
			String line;

			File refFolder = new File("referenceData/" + type);
			File[] listOfRefFiles = refFolder.listFiles();

			if (listOfFiles == null)
				listOfFiles = new File[0];
			if (listOfRefFiles == null)
				listOfRefFiles = new File[0];

			// ---------------------------Create Header for
			// Script----------------------------
			DcOrderScriptBuffer
					.write("--**************************************************************");
			DcOrderScriptBuffer.print('\n');
			DcOrderScriptBuffer.print("-- SCRIPT NAME:     "
					+ combinedFile.getName());
			DcOrderScriptBuffer.print('\n');
			DcOrderScriptBuffer.print("-- AUTHOR:          " + developerName);
			DcOrderScriptBuffer.print('\n');
			DcOrderScriptBuffer.print("-- DATE:            " + date);
			DcOrderScriptBuffer.print('\n');

			// -----------------------------------------------------------------

			FileReader fReader = null;
			BufferedReader temp = null;
			for (int i = 0; i < listOfRefFiles.length; i++) {
				if (listOfRefFiles[i].isFile()) {
					fReader = new FileReader(listOfRefFiles[i]);
					System.out.println("File " + listOfRefFiles[i].getName());
					temp = new BufferedReader(fReader);
					while ((line = temp.readLine()) != null) {
						DcOrderScriptBuffer.print(line);
						DcOrderScriptBuffer.print('\n');

					}

				}
			}

			if (fReader != null) {
				fReader.close();
				temp.close();
			}

			for (int i = 0; i < listOfFiles.length; i++) {
				DcOrderScriptBuffer.print('\n');
				if (listOfFiles[i].isFile()) {
					System.out.println("File " + listOfFiles[i].getName());
					fReader = new FileReader(listOfFiles[i]);
					temp = new BufferedReader(fReader);
					while ((line = temp.readLine()) != null) {
						DcOrderScriptBuffer.print(line);
						DcOrderScriptBuffer.print('\n');
					}
				}
			}

			if (fReader != null) {
				fReader.close();
				temp.close();
			}

			temp = null;
			fReader = null;

			DcOrderScriptBuffer.print("\nEND;\n");
			DcOrderScriptBuffer.print("/");

		} catch (IOException e) {
			System.out.println(e.getMessage());
		} finally {
			try {

				DcOrderScriptWriter.flush();
				DcOrderScriptWriter.close();
				DcOrderScriptBuffer.flush();
				DcOrderScriptBuffer.close();
				DcOrderScriptBuffer = null;
				DcOrderScriptWriter = null;
				System.gc();
				FileUtils.cleanDirectory(automatedIssuesDirectory);
			} catch (IOException e) {
				System.out.println(e.getMessage());
			}

		}

	}

}
