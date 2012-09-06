function lookupElementByXPath(path) { 
    var evaluator = new XPathEvaluator(); 
    var result = evaluator.evaluate(path, document.documentElement, null,XPathResult.FIRST_ORDERED_NODE_TYPE, null); 
    return  result.singleNodeValue; 
} 

function insertAfter(referenceNode, newNode) {
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
}

var settings;

var init = function(){

	var repoName = document.getElementsByClassName('js-current-repository').item(0).innerHTML;
	var branchName = document.getElementsByClassName('css-truncate-target').item(2).innerHTML;

	var commandURL = "github-pr://" + repoName + "/" + branchName;

	var link = document.createElement('a');
	link.setAttribute('href', commandURL);
	link.setAttribute('style', 'float:right');

	var image = document.createElement('img');
	var image_url = chrome.extension.getURL("download_icon_small.png");

	image.setAttribute('src', image_url);
	image.setAttribute('width', '25px');
	image.setAttribute('height', '25px');
	image.setAttribute('style', 'padding:5px 5px 0 0;');

	link.appendChild(image);
	
	var metaDivPath = "/html/body/div/div[2]/div/div[2]/div/div/div/div";
	var metaDivNode = lookupElementByXPath(metaDivPath);

	metaDivNode.appendChild(link);
	//insertAfter(branchNode.parentNode.parentNode.parentNode,link);

}

chrome.extension.sendMessage({message: "getSettings"}, function(response) {
	settings = response;
  console.log(settings["gitfolder"]);
  init();
});


