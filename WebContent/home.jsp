<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
	pageEncoding="ISO-8859-1"%>
<%@taglib prefix="s" uri="/struts-tags"%>
<%@ page import="java.lang.*"%>
<!DOCTYPE html>
<html lang="en">
<head>
<!-- <meta http-equiv="content-type" content="text/html; charset=UTF-8"> -->
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta charset="utf-8">
<title>DCOrder</title>
<title></title>
<meta name="generator" content="Bootply" />
<meta name="viewport"
	content="width=device-width, initial-scale=1, maximum-scale=1">

<!-- <link href="bootstrap/css/bootstrap.min.css" rel="stylesheet"> -->


<link rel="stylesheet"
	href="bootstrap/css/bootstrap.min.css">
<link rel="stylesheet"
	href="bootstrap/css/bootstrap-theme.min.css">
<script src="jquery/js/jquery-1.11.1.min.js"></script>
<script src="bootstrap/js/bootstrap.min.js"></script>


<s:hidden id="callCount" value="%{getIssuesCallCount}" name="callCount"/>


<script type="text/javascript">
$(function(){
	  
	  $(".dropdown-menu li a").click(function(){
	    
	    /* $(".btn:first-child").text($(this).text());
	     $(".btn:first-child").val($(this).text()); */
	     
		  $("#drpdwn").text($(this).text());
		  $("#drpdwn").val($(this).text());
		  $("#type").val($(this).text());
	  });

	});


function submitForm(id) {
	document.forms[id].submit();
}


function getissueData(id){
	var issueCallCount='${getIssuesCallCount}';
	if(issueCallCount == '' )
		document.forms[id].submit();
}
</script>

<style type="text/css">
.bs-example {
	margin: 20px;
}

.DivToScroll{   
    background-color: #F5F5F5;
    border: 1px solid #DDDDDD;
    border-radius: 4px 0 4px 0;
    color: #3B3C3E;
    font-size: 12px;
    font-weight: bold;
    left: -1px;
    padding: 10px 7px 5px;
}

.DivWithScroll{
    height:400px;
    overflow:scroll;
    overflow-x:hidden;
}
</style>

<%--  <script src="//html5shim.googlecode.com/svn/trunk/html5.js"></script> --%>

<link rel="shortcut icon" href="bootstrap/img/favicon.ico">
<link rel="apple-touch-icon" href="bootstrap/img/apple-touch-icon.png">
<link rel="apple-touch-icon" sizes="72x72"
	href="bootstrap/img/apple-touch-icon-72x72.png">
<link rel="apple-touch-icon" sizes="114x114"
	href="bootstrap/img/apple-touch-icon-114x114.png">

<!-- CSS code from Bootply.com editor -->

<style type="text/css">
.navbar-static-top {
	margin-bottom: 20px;
}

i {
	font-size: 18px;
}

footer {
	margin-top: 20px;
	padding-top: 20px;
	padding-bottom: 20px;
	background-color: #efefef;
}

.nav>li .count {
	position: absolute;
	bottom: 12px;
	right: 8px;
	font-size: 10px;
	font-weight: normal;
	background: rgba(51, 200, 51, 0.55);
	color: rgba(255, 255, 255, 0.9);
	line-height: 1em;
	padding: 2px 4px;
	-webkit-border-radius: 10px;
	-moz-border-radius: 10px;
	-ms-border-radius: 10px;
	-o-border-radius: 10px;
	border-radius: 10px;
}
</style>
</head>


<body onload="getissueData('getIssues');">
<form action="getIssues" id = "getIssues"></form>

	<!-- Header -->
	<div id="top-nav" class="navbar navbar-inverse navbar-static-top">
		<div class="container">
			<div class="navbar-header">
				<button type="button" class="navbar-toggle" data-toggle="collapse"
					data-target=".navbar-collapse">
					<span class="icon-toggle"></span>
				</button>
				<a class="navbar-brand" href="#">Ensemble - CSM</a>
			</div>
			<div class="navbar-collapse collapse">
				<ul class="nav navbar-nav navbar-right">

					<li class="dropdown"><a class="dropdown-toggle"
						data-toggle="dropdown" href="#"> <i
							class="glyphicon glyphicon-user"></i> DC Order <span
							class="caret"></span></a>
						<ul id="g-account-menu" class="dropdown-menu">
							<li><a href="admin.jsp">Admin Console</a></li>
							<li><a href="#"><i class="glyphicon glyphicon-lock"></i>
									Logout</a></li>
						</ul></li>
				</ul>
			</div>
		</div>
		<!-- /container -->
	</div>
	<!-- /Header -->

	<!-- Main -->
	<div class="container">

		<!-- upper section -->
		<div class="row">
			<div class="col-md-3">
				<!-- left -->
				<a href="#"><strong><i
						class="glyphicon glyphicon-briefcase"></i> Toolbox</strong></a>
				<hr>

				<ul class="nav nav-pills nav-stacked">
					<li><a href="#"><i class="glyphicon glyphicon-flash"></i>
							Alerts</a></li>
					<li><a href="#"><i class="glyphicon glyphicon-link"></i>
							Links</a></li>
					<li><a href="#"><i class="glyphicon glyphicon-list-alt"></i>
							Reports</a></li>
					<li><a href="#"><i class="glyphicon glyphicon-book"></i>
							Books</a></li>
					<li><a href="#"><i class="glyphicon glyphicon-briefcase"></i>
							Tools</a></li>
					<li><a href="#"><i class="glyphicon glyphicon-time"></i>
							Real-time</a></li>
					<li><a href="#"><i class="glyphicon glyphicon-plus"></i>
							Advanced..</a></li>
				</ul>

				<hr>

			</div>
			<!-- /span-3 -->
			<div class="col-md-9">

				<!-- column 2 -->


				<a href="#"><strong><i
						class="glyphicon glyphicon-dashboard"></i> My Dashboard</strong></a>

				<hr>

				<div class="row">
					<!-- center left-->
					<div class="col-md-7">

						<hr>

						<div class="panel panel-default">
							<div class="panel-heading">
								<h4>DC_ORDER Issue Status</h4>
							</div>
							<div class="panel-body">

								<small>Complete</small>
								<div class="progress">
									<div class="progress-bar progress-bar-success"
										role="progressbar" style="width: ${pendingCount}%">
										<span class="sr-only">${pendingCount}% Complete</span>
									</div>
								</div>
								<small>In Progress</small>
								<div class="progress">
									<div class="progress-bar progress-bar-info" role="progressbar"
										aria-valuenow="20" aria-valuemin="0" aria-valuemax="100"
										style="width: ${compCount}%">
										<span class="sr-only">${compCount}% Complete</span>
									</div>
								</div>
							<%-- 	<small>At Risk</small>
								<div class="progress">
									<div class="progress-bar progress-bar-danger"
										role="progressbar" aria-valuenow="80" aria-valuemin="0"
										aria-valuemax="100" style="width: 80%">
										<span class="sr-only">80% Complete</span>
									</div>
								</div> --%>

							</div>
							<!--/panel-body-->
						</div>
						<!--/panel-->

					</div>
					<!--/col-->

					<!--center-right-->
					<div class="col-md-5">

						<ul class="nav nav-justified">
							<li><a href="#"><i class="glyphicon glyphicon-cog"></i></a></li>
							<li><a href="#"><i class="glyphicon glyphicon-heart"></i></a></li>
							<li class="dropdown"><a href="#" class="dropdown-toggle"
								data-toggle="dropdown"><i
									class="glyphicon glyphicon-comment"></i><span class="count">3</span></a>
								<ul class="dropdown-menu" role="menu">
									<li><a href="#">1. Is there a way..</a></li>
									<li><a href="#">2. Hello, admin. I would..</a></li>
									<li><a href="#"><strong>All messages</strong></a></li>
								</ul></li>
							<li><a href="#"><i class="glyphicon glyphicon-user"></i></a></li>
							<li><a title="Add Widget" data-toggle="modal"
								href="#addWidgetModal"><span
									class="glyphicon glyphicon-plus-sign"></span></a></li>
						</ul>

						<hr>

						<p>This is internal portal for management of DC Order Issues.
							You can use this portal to create and submit fixes for issues
							assigned to your CUID.</p>
						<p>Contact Kunal Joshi/Vishal Garg for any doubts regarding
							issues.</p>

						<hr>

						<div class="btn-group btn-group-justified">
							<a href="#" class="btn btn-info col-sm-3"> <i
								class="glyphicon glyphicon-plus"></i><br> Service
							</a> <a href="#" class="btn btn-info col-sm-3"> <i
								class="glyphicon glyphicon-cloud"></i><br> Cloud
							</a> <a href="#" class="btn btn-info col-sm-3"> <i
								class="glyphicon glyphicon-cog"></i><br> Tools
							</a> <a href="#" class="btn btn-info col-sm-3"> <i
								class="glyphicon glyphicon-question-sign"></i><br> Help
							</a>
						</div>

					</div>

				</div>
			</div>

		</div>
		<div class="row ">

			<div class="col-md-12">
				<hr>
				<a href="#"><strong><i
						class="glyphicon glyphicon-list-alt"></i> Issues</strong></a>
				<hr>
			</div>
			<div class="container DivWithScroll">
            <table class="table table-striped">
              <thead>
                <tr>
                  <th>Issue ID</th>
                  <th>Title</th>
                  <th>Developer</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                <s:iterator value="issueList">
                  <tr>
                    <td><s:property value="issueID" /></td>
                    <td><s:property value="title" /></td>
                    <td><s:property value="developerName" /></td>
                    <td><s:property value="status" /></td>
                  </tr>
                </s:iterator>
              </tbody>
            </table>
          </div>
			<div class="container">


				<hr>

				<div class="panel panel-default">
					<div class="panel-heading">
						<div class="panel-title">
							<i class="glyphicon glyphicon-wrench pull-right"></i>
							<h4>Submit Script</h4>
						</div>
					</div>
					<div class="panel-body">

						<form class="form form-vertical" action="submitScript"
							id="submitScript">
							<div class="control-group">
								<label>Developer Name</label>
								<div class="controls">
									<input type="text" class="form-control"
										placeholder="Developer Name" name="developerName">
								</div>
							</div>
							<div class="control-group">
								<label>Title</label>
								<div class="controls">
									<input type="text" class="form-control"
										placeholder="Issue Description" name="issueDesc">

								</div>
							</div>

							<%-- <div class="control-group">
								<label>Issue Type </label>
								<div class="menu-item dropdown">
									<select id="myList" class="menu-item dropdown">
										<option value="DC_ORDER">DC_ORDER</option>
										<option value="CANCEL_ORDER">CANCEL_ORDER</option>
										<option value="OTHER">OTHER</option>
									</select>
								</div>
							</div> --%>

							<div class="control-group" style="position: relative; top: 10px;">
								<!-- <label>Issue Type </label> -->
								<div class="btn-group">
									<button data-toggle="dropdown"
										class="btn btn-default dropdown-toggle form-control" name="drpdwn" id= "drpdwn">
										Issue Type <span class="caret"></span>
									</button>
									<ul class="dropdown-menu">
										<li><a href="javascript:return false;">DC_ORDER</a></li>
										<li><a href="javascript:return false;">CANCEL_ORDER</a></li>
										<li><a href="javascript:return false;">OTHER</a></li>
									</ul>
								</div>
							</div>

							
							<input type="hidden" name="type" id = "type" value = "DC_ORDER">
							
							
							<div class="control-group" style="position: relative; top: 15px;">
								<label>Script</label>
								<div class="controls">
									<textarea class="form-control" name="script"></textarea>
								</div>
							</div>

							<div class="control-group">
								<label></label>
								<div class="controls">
									<button type="submit" class="btn btn-primary">Submit</button>
								</div>
							</div>
						</form>
					</div>
				</div>
			</div>
		</div>
	</div>





	<footer class="text-center"></footer>



	<script type='text/javascript'>
		$(document).ready(function() {

		});
	</script>

	<script>
		(function(i, s, o, g, r, a, m) {
			i['GoogleAnalyticsObject'] = r;
			i[r] = i[r] || function() {
				(i[r].q = i[r].q || []).push(arguments)
			}, i[r].l = 1 * new Date();
			a = s.createElement(o), m = s.getElementsByTagName(o)[0];
			a.async = 1;
			a.src = g;
			m.parentNode.insertBefore(a, m)
		})(window, document, 'script',
				'//www.google-analytics.com/analytics.js', 'ga');
		ga('create', 'UA-40413119-1', 'bootply.com');
		ga('send', 'pageview');
	</script>
	<!-- Quantcast Tag -->
	<script type="text/javascript">
		var _qevents = _qevents || [];

		(function() {
			var elem = document.createElement('script');
			elem.src = (document.location.protocol == "https:" ? "https://secure"
					: "http://edge")
					+ ".quantserve.com/quant.js";
			elem.async = true;
			elem.type = "text/javascript";
			var scpt = document.getElementsByTagName('script')[0];
			scpt.parentNode.insertBefore(elem, scpt);
		})();

		_qevents.push({
			qacct : "p-0cXb7ATGU9nz5"
		});
	
		
	</script>
</body>
</html>