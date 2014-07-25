<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
	pageEncoding="ISO-8859-1"%>
<%@taglib prefix="s" uri="/struts-tags"%>
<%@ page import="java.lang.*"%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="">
<meta name="author" content="">

<title>Admin Console</title>
<link href="bootstrap/css/bootstrap.min.css" rel="stylesheet">
<link href="bootstrap/css/dashboard.css" rel="stylesheet">


<!-- <link rel="stylesheet" href="checkBox/css/bootstrap.css" /> -->
<link rel="stylesheet" href="checkBox/css/font-awesome.css" />
<link rel="stylesheet"
	href="checkBox/css/awesome-bootstrap-checkbox.css" />
<link rel="stylesheet" href="checkBox/css/build.css" />

<script src="jquery/js/jquery-1.11.1.min.js"></script>
<script src="bootstrap/js/bootstrap.min.js"></script>
<script src="bootstrap/js/docs.min.js"></script>

<script type="text/javascript">
	var gRadioValue = '';
	function populateTable() {
		document.getElementById('populatePage').submit();
	}

	function submitForm(id) {
		document.forms[id].submit();
	}

	function setText(id) {
		var s = document.getElementById(id);
		s.value = gRadioValue;
	}
	
	function getScriptTable(id){
		var issueCallCount='${getIssuesCallCount}';
		if(issueCallCount == '' )
			document.forms[id].submit();
	}


    $(window).load(function(){
    	var scriptVal = <s:property value="script" />;
    	if(scriptVal != null)
        $('#editModal').modal('show');
    });

	/* 	function showModal() {

	 $('#myModal').modal('show');
	 alert('empty');
	 } */
</script>

<style type="text/css">
</style>



</head>

<!-- <body  getScriptTable('populatePage')"> -->

<body>

	<s:property value="script" />

	<div class="navbar navbar-inverse navbar-fixed-top">
		<div class="container-fluid">
			<div class="navbar-header">
				<button type="button" class="navbar-toggle" data-toggle="collapse"
					data-target=".navbar-collapse">
					<span class="sr-only">Toggle navigation</span> <span
						class="icon-bar"></span> <span class="icon-bar"></span> <span
						class="icon-bar"></span>
				</button>
				<a class="navbar-brand" href="#">Ensemble CSM</a>
			</div>
			<div class="navbar-collapse collapse">
				<ul class="nav navbar-nav navbar-right">

					<li class="dropdown"><a class="dropdown-toggle"
						data-toggle="dropdown" href="#"> <i
							class="glyphicon glyphicon-user"></i>ADMIN CONSOLE<span
							class="caret"></span></a>
						<ul id="g-account-menu" class="dropdown-menu">
							<li><a href="home.jsp">Home</a></li>
							<li><a href="#"><i class="glyphicon glyphicon-lock"></i>
									Logout</a></li>
						</ul></li>
				</ul>
			</div>
		</div>
	</div>



	<div class="container-fluid">
		<div class="row">
			<div class="col-sm-3 col-md-2 sidebar">
				<ul class="nav nav-sidebar">
					<li class="active"><a href="admin.jsp">Overview</a></li>
					<li><a href="generateScript.jsp">Generate Script</a></li>
					<li><a href="issueInput.jsp">Issue Input</a></li>
				</ul>

			</div>

			<div class="col-sm-9 col-sm-offset-3 col-md-10 col-md-offset-2 main">
				<h1 class="page-header">Script History</h1>

				<form action="populatePage" id="populatePage">
					<button type="submit" class="btn btn-primary" style = "position: relative;top: -60px ; left : 90%">
						<span class="glyphicon glyphicon-refresh"></span>
					</button>
				</form>



				<form action="uploadScript" id="uploadScript">

					<div class="table-responsive">
						<table class="table table-striped">
							<thead>
								<tr>
									<th>
										<%-- <button type="button" class="btn btn-primary"
											onclick="submitForm('populatePage');">
											<span class="glyphicon glyphicon-refresh"></span>
										</button> --%>
									</th> 
									<th>Date Created</th>
									<th>Script Name</th>
									<th>Type</th>
									<th>Created By</th>
								</tr>
							</thead>
							<tbody>
								<s:iterator value="foldercontents">

									<tr>
										<td>
											<div class="radio radio-info"
												style="position: relative; bottom: 15px">
												<input type="radio" name="fileToUpload" id="${fileName}"
													value="${type}/${fileName}"
													onClick="gRadioValue =this.value;"> <label
													for="${fileName}"> </label>
											</div>
										</td>
										<td><s:property value="creationDate" /></td>
										<td><s:property value="fileName" /></td>
										<td><s:property value="type" /></td>
										<td><s:property value="createdBy" /></td>
									</tr>


								</s:iterator>
							</tbody>
						</table>
					</div>

					<button type="submit" class="btn btn-primary" data-toggle="modal"
						data-target="#myModal">
						<span class="glyphicon glyphicon-cloud-upload"> Upload</span>
					</button>



				</form>
				<form action="editScript" id="editScript">
					<input type="hidden" name="editScriptName" id="editScriptName"
						value=''>

					<!-- onclick="setText('editScriptName');" -->
					<button type="submit" class="btn btn-primary"
						style="position: relative; top: -34px; left: 200px"
						onclick="setText('editScriptName');">
						<span class="glyphicon glyphicon-pencil"> Edit</span>
					</button>
				</form>

			</div>
		</div>
	</div>



	<!-- Bootstrap core JavaScript
    ================================================== -->
	<!-- Placed at the end of the document so the pages load faster -->





	<!-- Button trigger modal -->
	<!-- <button class="btn btn-primary btn-lg" data-toggle="modal" data-target="#myModal">
  Launch demo modal
</button> -->

	<div style="position: absolute; left: 50%">
		<s:property value="status" />
	</div>

	<div class="modal fade" id="myModal" tabindex="-1">
		<div class="modal-dialog">
			<div class="modal-content">
				<div class="modal-header">
					<button type="button" class="close" data-dismiss="modal">
						<span>&times;</span><span class="sr-only">Close</span>
					</button>
					<h4 class="modal-title" id="myModalLabel">Uploading Script</h4>
				</div>
				<div class="modal-body">
					<div class="progress">
						<div class="progress-bar" style="width: 100%;">
							Uploading....</div>
					</div>
				</div>
			</div>
			<!-- <div class="modal-footer">
					<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
					<button type="button" class="btn btn-primary">Ok</button>
				</div> -->
		</div>
	</div>
	<div class="modal fade" id="editModal" tabindex="-1">
		<div class="modal-dialog modal-lg">
			<div class="modal-content">
				<div class="modal-header">
					<button type="button" class="close" data-dismiss="modal">×</button>
					<h4 class="modal-title">Edit Script</h4>
				</div>
				<div class="modal-body">
					<label class="control-label no-padding-right" for="description">Script</label>

					<textarea class="form-control" id="description" name="">
						${script}
						
						
						</textarea>

					<div class="modal-footer">
						<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
						<button type="button" class="btn btn-primary">Save
							changes</button>
					</div>
				</div>
				<!-- /.modal-content -->
			</div>
			<!-- /.modal-dialog -->
		</div>
		<!-- /.modal -->
	</div>
</body>
</html>
