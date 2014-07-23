package com.ctli.dco.service.impl;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import com.ctli.dco.service.ISubmitScriptService;

public class SubmitScriptService implements ISubmitScriptService {

	public void makeScript(String developerName2, String issueDesc2,
			String script2, String type) {
		
		File directory = new File("flatfiles/"+ type);
		if (!directory.exists()) {
			if (directory.mkdir()) {
				System.out.println("Directory "+ directory.getAbsolutePath() +" is created!");
			} else {
				System.out.println("Failed to create directory : "+ directory.getAbsolutePath());
			}
		}

		String filePath = "flatfiles/"+ type +"/" + developerName2 + ".txt";

		try {
			String tempfilePath = "flatfiles/" + type +"/" + developerName2 + ".tmp";
			File file = new File(filePath);
			File tempFile = new File(tempfilePath);
			BufferedReader br = null;
			PrintWriter pw = new PrintWriter(new FileWriter(tempFile));
			boolean editFlag = false;

			if (!file.exists()) {
				file.createNewFile();
			}

			String sCurrentLine;
			String lastLine = "---------------------------END---------------------------------";

			br = new BufferedReader(new FileReader(filePath));

			while ((sCurrentLine = br.readLine()) != null) {
				if (sCurrentLine.equalsIgnoreCase("--" + issueDesc2.trim()
						+ "--" + developerName2.trim())) {

					editFlag = true;
					while (!sCurrentLine.equals(lastLine)) {
						sCurrentLine = br.readLine();
					}
					if (editFlag)
						sCurrentLine = br.readLine();
				}

				pw.println(sCurrentLine);
				pw.flush();
			}

			pw.close();
			br.close();

			if (editFlag) {
				// Delete the original file
				if (!file.delete()) {
					System.out.println("Could not delete file");
				}

				// Rename the new file to the filename the original file had.
				if (!tempFile.renameTo(file))
					System.out.println("Could not rename file");
			} else {
				if (!tempFile.delete()) {
					System.out.println("Could not delete tempfile");
				}
			}

			FileWriter fw = new FileWriter(file.getAbsoluteFile(), true);
			BufferedWriter bw = new BufferedWriter(fw);
			bw.write("---------------------------------------------------------------\n");
			bw.write("--" + issueDesc2.trim() + "--" + developerName2.trim()
					+ "\n");
			bw.write("---------------------------------------------------------------\n\n");
			bw.write(script2);
			bw.write("\n\n---------------------------END---------------------------------");
			bw.write("\n\n");
			bw.close();
			fw.close();
			System.out.println("Done");

		} catch (IOException e) {

			System.out.println(e.getMessage());
		}

	}



}
