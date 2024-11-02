<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
				<![CDATA[
					var debugFeed = [];
					var debugFlag = false; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc, wageredPricePoint)
					{						
						var scenario = getScenario(jsonContext);
						var scenarioMainGame = getMainGameData(scenario);
						var scenarioBonus1 = getBonusData(scenario, 1);
						var scenarioBonus2 = getBonusData(scenario, 2);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');

						////////////////////
						// Parse scenario //
						////////////////////

						const gridCols      = 5;
						const gridRows      = 4;

						var triggerStr     = 'bonus';
						
						var playableCells = []; 
						var arrGridData  = [];

						arrGridData  = scenarioMainGame.split(",");

						////////////////////////////////////
						// Cash value conversion routines //
						////////////////////////////////////
						function getCurrencyInfoFromTopPrize()
						{
							var topPrize               = convertedPrizeValues[0];
							var strPrizeAsDigits       = topPrize.replace(new RegExp('[^0-9]', 'g'), '');
							var iPosFirstDigit         = topPrize.indexOf(strPrizeAsDigits[0]);
							var iPosLastDigit          = topPrize.lastIndexOf(strPrizeAsDigits.substr(-1));
							bCurrSymbAtFront           = (iPosFirstDigit != 0);
							strCurrSymb 	           = (bCurrSymbAtFront) ? topPrize.substr(0,iPosFirstDigit) : topPrize.substr(iPosLastDigit+1);
							var strPrizeNoCurrency     = topPrize.replace(new RegExp('[' + strCurrSymb + ']', 'g'), '');
							var strPrizeNoDigitsOrCurr = strPrizeNoCurrency.replace(new RegExp('[0-9]', 'g'), '');
							strDecSymb                 = strPrizeNoDigitsOrCurr.substr(-1);
							strThouSymb                = (strPrizeNoDigitsOrCurr.length > 1) ? strPrizeNoDigitsOrCurr[0] : strThouSymb;
						}

						function getPrizeInCents(AA_strPrize)
						{
							return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
						}

						function getCentsInCurr(AA_iPrize)
						{
							var strValue = AA_iPrize.toString();

							strValue = (strValue.length < 3) ? ('00' + strValue).substr(-3) : strValue;
							strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
							strValue = (strValue.length > 6) ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
							strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;
	
							return strValue;
						}


						///////////////////
						// Match 3 check //
						///////////////////
						const winCount = 3;
						const symbCountsIndex = 'ABCDEFGHIJKLMN';
						const bonusCountsIndex = '12';
						var arrSymbCounts = [0,0,0,0,0,0,0,0,0,0,0,0,0,0];
						var arrBonusCounts = [0,0];
						var bonusPlay1 = false;
						var bonusPlay2 = false;

						for (var i = 0; i < arrGridData.length; i++)
						{
							if (arrGridData[i].length > 1)
							{	// Instant Win Multiplier

							}
							else
							{
								if (symbCountsIndex.indexOf(arrGridData[i]) > -1)
								{
									arrSymbCounts[symbCountsIndex.indexOf(arrGridData[i])]++;
								}
								else if (bonusCountsIndex.indexOf(arrGridData[i]) > -1)
								{
									arrBonusCounts[bonusCountsIndex.indexOf(arrGridData[i])]++;
								}
							}
						}

						if (arrBonusCounts[bonusCountsIndex.indexOf('1')] == winCount)
						{
							bonusPlay1 = true;
						}
						else if (arrBonusCounts[bonusCountsIndex.indexOf('2')] == winCount)
						{
							bonusPlay2 = true;
						}


						///////////////////////
						// Output Game Parts //
						///////////////////////
						const symbPrizes       = 'ABCDEFGHIJKLMN';
						const symbBonusWin     = 'Z';
						const symbBonusPrizes  = 'ABCDEFGHIJKLMNO';
						const symbBonusWins    = '12TSX';

						const mainCellSize  = 24;
						const bonusCellSize = 36;
						const cellMargin    = 1;
						const cellSizeX     = 72;
						const cellSizeY     = 48;
						const cellTextX     = 37; 
						const cellTextY		= 20;
						const cellTextY2    = 40; 
						const bonusCellTextX = 19; 
						const bonusCellTextY = 20;
						const cellSmTextX   = 13;
						const cellSmTextY   = 15;

						const colourAquamarine = '#7fffd4';
						const colourBlack   = '#000000';
						const colourBlue    = '#99ccff';
						const colourBrown   = '#990000';
						const colourGreen   = '#00cc00';
						const colourMidGreen= '#00ff00';
						const colourDkGrey  = '#202020';
						const colourMidGrey = '#7c7c7c';
						const colourLemon   = '#ffff99';
						const colourLilac   = '#ccccff';
						const colourLime    = '#ccff99';
						const colourDeepMag = '#b300b3';
						const colourNavy    = '#0000ff';
						const colourOrange  = '#ff7c00';
						const colourPeach   = '#ffcc99';
						const colourPink    = '#ffccff';
						const colourPurple  = '#cc99ff';
						const colourRed     = '#ff9999';
						const colourScarlet = '#ff0000';
						const colourWhite   = '#ffffff';
						const colourYellow  = '#ffff00';

						//								A			B				C			D			E			F				G				H			I			J			K				L				M				N	
						// const prizeColours       = [colourLemon, colourPink, colourPurple, colourBlue, colourRed, colourAquamarine, colourPeach, colourLilac, colourBrown, colourGreen, colourOrange, colourDeepMag, colourMidGreen, colourScarlet];
						//								A			B				C			D			E			F				G				H			I			J			K				L				M				N			O
						const bonusBoxColours    = [colourLemon, colourPink, colourPurple, colourBlue, colourRed, colourAquamarine, colourPeach, colourLilac, colourBrown, colourGreen, colourOrange, colourDeepMag, colourMidGreen, colourScarlet, colourYellow];
						const bonusSBoxColours   = [colourNavy, colourMidGrey, colourBlack, colourBlack, colourDkGrey];
						const bonusSTextColours  = [colourYellow, colourYellow, colourWhite, colourWhite, colourYellow];

						var r = [];

						var boxColourStr  = '';
						var canvasIdStr   = '';
						var elementStr    = '';
						var symbAction    = '';
						var symbDesc      = '';
						var symbPrize     = '';
						var symbSpecial   = '';
						var symbBonus     = '';
						var textColourStr = '';

						function showSymb(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + (mainCellSize + 2 * cellMargin).toString() + '" height="' + (mainCellSize + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 12px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + mainCellSize.toString() + ', ' + mainCellSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (mainCellSize - 2).toString() + ', ' + (mainCellSize - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + cellSmTextX.toString() + ', ' + cellSmTextY.toString() + ');');

							r.push('</script>');
						}

						///////////////////////////
						// Main Game Symbols Key //
						///////////////////////////
						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var prizeIndex = 0; prizeIndex < symbPrizes.length; prizeIndex++)
						{
							symbPrize    = symbPrizes[prizeIndex];
							canvasIdStr  = 'cvsKeySymb' + symbPrize;
							elementStr   = 'keyPrizeSymb' + symbPrize;
							boxColourStr = colourWhite; //prizeColours[prizeIndex];
							symbDesc     = 'symb' + symbPrize;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbPrize);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						//////////////////////////
						// Main Game Colour Key //
						//////////////////////////
						const arrCellBackgroundColour = [colourWhite, colourLime,  colourYellow, colourBlue];
						const arrCellBackgroundDesc   = ['', 'winMatch', 'winIW', 'triggerBonus'];

						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleWinningColoursKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keyColour", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var winType = 1; winType < arrCellBackgroundColour.length; winType++)
						{
							symbPrize    = winType.toString();
							canvasIdStr  = 'cvsKeySymb' + symbPrize;
							elementStr   = 'keyPrizeSymb' + symbPrize;
							boxColourStr = arrCellBackgroundColour[winType];

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, "");

							r.push('</td>');
							r.push('<td>' + getTranslationByName(arrCellBackgroundDesc[winType], translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');						
						r.push('</div>');

						///////////////
						// Main Game //
						///////////////
						var gridCanvasHeight = gridRows * cellSizeY + 2 * cellMargin;
						var gridCanvasWidth  = gridCols * cellSizeX + 2 * cellMargin;
						var isAction         = false;
						var isBonusSymbs     = false;
						var prizeStr         = '';

						function showGridSymbs(A_strCanvasId, A_strCanvasElement, A_arrGrid)
						{
							var canvasCtxStr  = 'canvasContext' + A_strCanvasElement;
							var cellIndex     = -1;
							var cellText1     = '';
							var cellText2     = '';
							var cellX         = 0;
							var cellY         = 0;
							var isIWCell      = false;
							var isBonusWinCell = false;
							var isPrizeCell   = false;
							var isSpecialCell = false;
							var symbCell      = '';
							var symbIndex     = -1;
							var tempStr       = '';

							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridRow = 0; gridRow < gridRows; gridRow++)
							{
								for (var gridCol = 0; gridCol < gridCols; gridCol++)
								{
									cellIndex     = gridCol + gridRow * gridCols;
							
									symbCell      = A_arrGrid[cellIndex];
									isIWCell	  = (symbCell.length > 1);
									isBonusWinCell= (arrBonusCounts[bonusCountsIndex.indexOf(A_arrGrid[cellIndex])] == winCount); 
									isPrizeCell   = (arrSymbCounts[symbCountsIndex.indexOf(A_arrGrid[cellIndex])] == winCount) || (isIWCell) || (isBonusWinCell);
									cellText1	  = (isIWCell) ? getTranslationByName('winIW', translations) : (((A_arrGrid[cellIndex] == '1') || (A_arrGrid[cellIndex] == '2')) ? getTranslationByName("symb" + A_arrGrid[cellIndex], translations) : symbCell);
									cellText2     = (isIWCell) ? symbCell : (((A_arrGrid[cellIndex] == '1') || (A_arrGrid[cellIndex] == '2')) ? getTranslationByName("bonus", translations) : convertedPrizeValues[getPrizeNameIndex(prizeNames, 'm' + symbCell)]);
									boxColourStr  = (isPrizeCell) ? ((isIWCell) ? arrCellBackgroundColour[2] : ((isBonusWinCell) ? arrCellBackgroundColour[3] : arrCellBackgroundColour[1])) : arrCellBackgroundColour[0];
									textColourStr = colourBlack; 
									cellX         = gridCol * cellSizeX;
									cellY         = gridRow * cellSizeY;
									if (isIWCell)
									{
										switch (symbCell[0])
										{
											case "W" : 
												cellText2 = '1x';
											break;
											case "X" :
												cellText2 = '2x';
											break;
											case "Y" :
												cellText2 = '5x';
											break;											
											case "Z" :
												cellText2 = '10x';
											break;											
										}
										cellText2 += ' ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, 'i' + symbCell[1])];
									}

									r.push(canvasCtxStr + '.font = "bold 10px Arial";');
									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									r.push(canvasCtxStr + '.fillText("' + cellText1 + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									r.push(canvasCtxStr + '.fillText("' + cellText2 + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY2).toString() + ');');
								}
							}
							r.push('</script>');
						}

						r.push('<div style="clear:both">');
						r.push('<p> <br>' + getTranslationByName("mainGame", translations).toUpperCase() + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						////////////////////
						// Main Game Grid //
						////////////////////
						canvasIdStr = 'cvsMainGrid';
						elementStr  = 'phaseMainGrid';

						r.push('<td style="padding-left:50px; padding-right:50px; padding-bottom:25px">');

						showGridSymbs(canvasIdStr, elementStr, arrGridData);

						r.push('</td>');

						r.push('</table>');
						r.push('</div>');

						////////////////
						// Bonus Game //
						////////////////
						if (bonusPlay1)
						{
							const iWheelPositions  = 16;
							const iNumWheels	   = 4;
							const arrWheelRefIndex = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","m","n"];
							const arrWheelMulti    = [100,50,30,25,20,15,10,8,6,5,4,3,2,1,2,1];
							const arrLetterWheel   = ["A","M","H","E","N","I","F","C","m","J","G","B","K","n","D","L"];
							const arrFirstWheel    = ["1","2","0","3","0","0","4","0","5","6","0","7","0","0","8","0"];
							const arrSecondWheel   = ["1","2","0","3","0","4","0","5","0","0","6","0","7","0","8","0"];
							const arrThirdWheel    = ["1","0","0","0","2","0","0","0","3","0","0","0","4","0","0","0"];
							var bonusGridCanvasHeight   = 1 * bonusCellSize + 2 * cellMargin;
							var bonusGridCanvasWidth    = iWheelPositions * bonusCellSize + 2 * cellMargin;

							function showBonusRow(A_strCanvasId, A_strCanvasElement, A_Multipliers, A_PosActive)
							{
								var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
								var cellIndex    = -1;
								var cellX        = 0;
								var cellY        = 0;
								var isPrizeCell  = false;
								var isWinCell    = false;
								var symbCell     = '';
								var symbIndex    = -1;

								r.push('<canvas id="' + A_strCanvasId + '" width="' + bonusGridCanvasWidth.toString() + '" height="' + bonusGridCanvasHeight.toString() + '"></canvas>');
								r.push('<script>');
								r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
								r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
								r.push(canvasCtxStr + '.textAlign = "center";');
								r.push(canvasCtxStr + '.textBaseline = "middle";');

								for (var gridCol = 0; gridCol < iWheelPositions; gridCol++)
								{
									symbCell      = (A_PosActive[gridCol] == true) ? A_Multipliers[gridCol] : "";
									boxColourStr  = (A_PosActive[gridCol] == true) ? colourLemon : colourMidGrey;
									textColourStr = colourBlack;
									cellX         = gridCol * bonusCellSize;

									r.push(canvasCtxStr + '.font = "bold 14px Arial";');
									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + bonusCellSize.toString() + ', ' + bonusCellSize.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (bonusCellSize - 2).toString() + ', ' + (bonusCellSize - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									r.push(canvasCtxStr + '.fillText("' + symbCell + '", ' + (cellX + bonusCellTextX).toString() + ', ' + (cellY + bonusCellTextY).toString() + ');');
								}
								r.push('</script>');
							}

							// Outermost wheel - Odd number means there's another spin
							var arrPosActive = [];
							var arrMultipliers = [];
							var turnStr   = '';
							var bonus1Data = scenarioBonus1.split(",");
							var turnQty = bonus1Data.length;
							var ringPos = -1;
							var bonusTotal = 0;

							getCurrencyInfoFromTopPrize();

							r.push('<p>' + getTranslationByName("bonusGame", translations).toUpperCase() + '</p>');

							// Display multipliers as wheel locations, all highlighted to begin, and as rings (1-3) "lock" show another line with only "alive" locations as highlighted.
							var spinText = '';
							var offset = 0;
							var prizeLetter = '';
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							for (var turnIndex = 0; turnIndex < turnQty; turnIndex++)
							{
								arrMultipliers = [];
								spinText = bonus1Data[turnIndex];
								arrPosActive = [true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true];
								// Display Multipliers all Active
								offset = parseInt(spinText, 10);
								prizeLetter = spinText[2]; 
								var startPos = arrLetterWheel.indexOf(prizeLetter);
								r.push('<tr class="tablebody">');
								turnStr = getTranslationByName("turnNum", translations) + ' ' + (turnIndex+1).toString() + ' ' + getTranslationByName("turnOf", translations) + ' ' + turnQty.toString();
								r.push('<td valign="top">' + turnStr + '</td>');
								for (var row = 0; row < iNumWheels; row++)
								{
									if (row > 0)	
									{
										r.push('<tr class="tablebody">');
										r.push('<td>');  // fills space at start of grid where turnStr fits
										r.push('</td>');
									}
									for (var col = 0; col < iWheelPositions; col++)
									{
										switch (row)
										{
											case 0 :
												ringPos = arrLetterWheel.indexOf(prizeLetter) - offset +1 + col;
												ringPos = (ringPos > iWheelPositions -1) ? (ringPos -= iWheelPositions) : ((ringPos < 0) ? (ringPos += iWheelPositions) : ringPos);
												arrMultipliers.push('x' + arrWheelMulti[arrWheelRefIndex.indexOf(arrLetterWheel[ringPos])]);
											break;
											case 1 :
												ringPos = arrFirstWheel.indexOf(parseInt(spinText[3], 10)) - offset + col +2; 
											break;
											case 2 :
												ringPos = arrSecondWheel.indexOf(parseInt(spinText[4], 10)) - offset + col +2; 
											break;
											case 3 :
												ringPos = arrThirdWheel.indexOf(parseInt(spinText[5], 10)) - offset + col +2;
											break;
										}
										ringPos = (ringPos > iWheelPositions -1) ? (ringPos -= iWheelPositions) : ((ringPos < 0) ? (ringPos += iWheelPositions) : ringPos);
										switch (row)
										{
											case 0 :
											break;
											case 1 :
												arrPosActive[col] = (arrFirstWheel[ringPos] == '0') ? false : arrPosActive[col];
											break;
											case 2 :
												arrPosActive[col] = (arrSecondWheel[ringPos] == '0') ? false : arrPosActive[col];
											break;
											case 3 :
												arrPosActive[col] = (arrThirdWheel[ringPos] == '0') ? false : arrPosActive[col];
											break;
										}
									}
									canvasIdStr   = 'cvsBonus1WinSummarySymb' + turnIndex.toString() + row.toString();
									elementStr    = 'keyBonus1WinSummarySymb' + turnIndex.toString() + row.toString();

									r.push('<td>');
									showBonusRow (canvasIdStr, elementStr, arrMultipliers, arrPosActive);
									r.push('</td>');
									if (row == iNumWheels -1)
									{
										for (var col = 0; col < iWheelPositions; col++)
										{
											if (arrPosActive[col] == true)
											{
												var multiplier = arrMultipliers[col];
											}
										}

										var prizeStr = convertedPrizeValues[getPrizeNameIndex(prizeNames, 'w' + prizeLetter.toUpperCase())];
										r.push('<td>');
										r.push(getCentsInCurr(wageredPricePoint));
										r.push(' ' + multiplier + ' = ' + prizeStr);
										r.push('</td>');
										bonusTotal += getPrizeInCents(prizeStr);
									}
									if (row > 0)	
									{
										r.push('</tr>');
									}
								}
								var nextTurnStr = ((parseInt(spinText[7] + spinText[8], 10) & 1) == 1) ? getTranslationByName("odd", translations) : getTranslationByName("even", translations);
								r.push('<td valign="top">' + nextTurnStr + '</td>');
								r.push('</tr>');
							}
							r.push('</table>');
							r.push('<p>' + getTranslationByName("bonusWin", translations) + ' : ' + getCentsInCurr(bonusTotal) + '</p>');
						}

						if (bonusPlay2)
						{
							function pad(num, size) 
							{
 								num = num.toString();
							    while (num.length < size) num = "0" + num;
    							return num;
							}

							r.push('<p>' + getTranslationByName("bonusGame", translations).toUpperCase() + '</p>');

							/////////////////////
							// Bonus Functions //
							/////////////////////
							function showBonusTotal(A_arrPrizes, A_arrPrizeNames, A_arrPrizeQtys, A_iMulti)
							{
								var bCurrSymbAtFront = false;
								var iBonusTotal 	 = 0;
								var iPrize      	 = 0;
								var iPrizeMulti   	 = 0;
								var iPrizeTotal 	 = 0;
								var strCurrSymb      = '';
								var strDecSymb  	 = '';
								var strThouSymb      = '';
								var strPrize      	 = '';

								getCurrencyInfoFromTopPrize();

								r.push('<p>' + getTranslationByName("bonusWin", translations) + ' : ' + '</p>');

								r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
								r.push('<tr class="tablehead">');
								r.push('<td>(</td>');

								for (prizeIndex = 0; prizeIndex < A_arrPrizes.length; prizeIndex++)
								{
									strPrize = A_arrPrizes[prizeIndex];
									iPrizeMulti = A_arrPrizeQtys[prizeIndex]
									iPrize = getPrizeInCents(strPrize);
									iPrizeTotal += iPrize * iPrizeMulti;
									 
									symbDesc      = A_arrPrizeNames[prizeIndex];
									canvasIdStr   = 'cvsBonusWinSummarySymb' + symbDesc;
									elementStr    = 'keyBonusWinSummarySymb' + symbDesc;
									isPrizeCell   = (symbBonusPrizes.indexOf(symbDesc) != -1);
									boxColourStr  = (isPrizeCell) ? bonusBoxColours[symbBonusPrizes.indexOf(symbDesc)] : bonusSBoxColours[symbBonusWins.indexOf(symbDesc)];
									textColourStr = (isPrizeCell) ? colourBlack : bonusSTextColours[symbBonusWins.indexOf(symbDesc)];

									r.push('<td align="center">');
									showSymb(canvasIdStr, elementStr, boxColourStr, textColourStr, symbDesc);
									r.push('</td>');

									r.push('<td>');
									r.push(strPrize + ' x ' + iPrizeMulti.toString());
									if (prizeIndex != A_arrPrizes.length -1)
									{
 										r.push(' + ');
										r.push('</td>');
									}
								}

								r.push(')' + '</td>'); 
								symbDesc      = 'X';
								canvasIdStr   = 'cvsBonusWinSummarySymb' + symbDesc;
								elementStr    = 'keyBonusWinSummarySymb' + symbDesc;
								boxColourStr  = bonusSBoxColours[symbBonusWins.indexOf(symbDesc)];
								textColourStr = bonusSTextColours[symbBonusWins.indexOf(symbDesc)];

								r.push('<td align="center">');
								showSymb(canvasIdStr, elementStr, boxColourStr, textColourStr, symbDesc);
								r.push('</td>');

								r.push('<td> ' + A_iMulti.toString() + '</td>');
								
								iBonusTotal = iPrizeTotal * A_iMulti;

								r.push('<td> = ' + getCentsInCurr(iPrizeTotal) + ' x ' + A_iMulti.toString() + ' = ' + getCentsInCurr(iBonusTotal) + '</td>');
								r.push('</tr>');
								r.push('</table>');
							}

							///////////////////////
							// Bonus Symbols Key //
							///////////////////////
							r.push('<div style="float:left; margin-right:50px">');
							r.push('<p>' + getTranslationByName("titleBonusSymbolsKey", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr class="tablehead">');
							r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
							r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
							r.push('</tr>');

							var textCash = '';

							for (var bonusIndex = 0; bonusIndex < symbBonusPrizes.length; bonusIndex++)
							{
								symbBonus     = symbBonusPrizes[bonusIndex];
								canvasIdStr   = 'cvsBonusKeySymb' + symbBonus;
								elementStr    = 'keyBonusSymb' + symbBonus;
								boxColourStr  = bonusBoxColours[bonusIndex];
								symbDesc      = 'symbBonus' + symbBonus;
								textCash	  = convertedPrizeValues[getPrizeNameIndex(prizeNames, 'g' + symbBonus)];

								r.push('<tr class="tablebody">');
								r.push('<td align="center">');

								showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbBonus);

								r.push('</td>');
								r.push('<td>' + textCash + '</td>');
								r.push('</tr>');
							}
							r.push('</table>');
							r.push('</div>');

							////////////////////////////
							// Additional Symbols Key //
							////////////////////////////
							r.push('<div style="float:left; margin-right:50px">');
							r.push('<p>' + getTranslationByName("titleAddtionalSymbolsKey", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr class="tablehead">');
							r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
							r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
							r.push('</tr>');

							for (var specialIndex = 0; specialIndex < symbBonusWins.length; specialIndex++)
							{
								symbSpecial   = symbBonusWins[specialIndex];
								canvasIdStr   = 'cvsBonusKeySymb' + symbSpecial;
								elementStr    = 'keyBonusSymb' + symbSpecial;
								boxColourStr  = bonusSBoxColours[specialIndex];
								textColourStr = bonusSTextColours[specialIndex];
								symbDesc      = 'symbBonus' + symbSpecial;

								r.push('<tr class="tablebody">');
								r.push('<td align="center">');

								showSymb(canvasIdStr, elementStr, boxColourStr, textColourStr, symbSpecial);

								r.push('</td>');
								r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
								r.push('</tr>');
							}

							r.push('</table>');
							r.push('</div>');

							r.push('<div style="clear:both">');
							r.push('<br>');

							/////////////////
							// Bonus Turns //
							/////////////////
							var bonusPrizes			= [];
							var bonusPrizeNames		= [];
							var bonusPrizeQtys      = [];
							const bonusLetterNames	= ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","X"];
							var bonusLetterCounts 	= [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1];
							var bonusSymb		  	= '';
							var colUpdated 		  	= -1;
							var lastRow 		  	= false;

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							// Bonus Table Headings Row
							r.push('<tr>');
							canvasIdStr = 'cvsBonusGridHeaderA' + pad(1, 2);
							elementStr  = 'phaseBonusGridHeaderA' + pad(1, 2);
							r.push('<td></td>');
							canvasIdStr = 'cvsBonusGridHeaderA' + pad(2, 2);
							elementStr  = 'phaseBonusGridHeaderA' + pad(2, 2);
							r.push('<td></td>');

							for (var i = 0; i < bonusLetterNames.length; i++)
							{
								symbDesc = bonusLetterNames[i];
								isPrizeCell = (symbBonusPrizes.indexOf(symbDesc) != -1);
								boxColourStr = (isPrizeCell) ? bonusBoxColours[symbBonusPrizes.indexOf(symbDesc)] : bonusSBoxColours[symbBonusWins.indexOf(symbDesc)];
								textColourStr = (isPrizeCell) ? colourBlack : bonusSTextColours[symbBonusWins.indexOf(symbDesc)];
								canvasIdStr = 'cvsBonusGridHeaderA' + symbDesc;
								elementStr  = 'phaseBonusGridHeaderA' + symbDesc;
								r.push('<td>');
								showSymb(canvasIdStr, elementStr, boxColourStr, textColourStr, symbDesc);
								r.push('</td>');
							}
							r.push('</tr>');

							// Bonus Table Base Values Row
							r.push('<tr>');
							for (var i = 2; i < 4; i++) // T & S
							{
								symbDesc = symbBonusWins[i];  
								canvasIdStr = 'cvsBonusGridStart' + symbDesc;
								elementStr  = 'phaseBonusGridStart' + symbDesc;
								r.push('<td>');
								showSymb(canvasIdStr, elementStr, colourBlack, colourWhite, symbDesc);
								r.push('</td>');
							}
							
							for (var i = 0; i < bonusLetterCounts.length; i++) // Values for all symbols as multiplier begins at 1
							{
								symbDesc = bonusLetterCounts[i].toString();
								canvasIdStr = 'cvsBonusGridStart' + i.toString() + symbDesc;
								elementStr  = 'phaseBonusGridStart' + i.toString() + symbDesc;
								r.push('<td>');
								showSymb(canvasIdStr, elementStr, colourWhite, colourBlack, symbDesc);
								r.push('</td>');
							}
							r.push('</tr>');

							// Bonus Table Values Rows
							for (var turnIndex = 0; turnIndex < scenarioBonus2.length; turnIndex++)
							{
								// Bonus Table Figure out display value (gA-gO, 1-2, X)
								bonusSymb = scenarioBonus2[turnIndex];
								if (bonusSymb == "1" || bonusSymb == "2")
								{
									bonusLetterCounts[bonusLetterCounts.length -1] += parseInt(bonusSymb, 10);
									colUpdated = bonusLetterCounts.length -1;
								}
								else
								{	
									if (bonusSymb != "X")
									{
										bonusLetterCounts[bonusSymb.charCodeAt(0) - 65]++;
										colUpdated = bonusSymb.charCodeAt(0) - 65;
									}
								}

								// Bonus Table Details
								r.push('<tr>');
								symbDesc = (turnIndex + 1).toString();
								canvasIdStr = 'cvsBonusGrid' + pad(turnIndex, 2) + symbDesc;
								elementStr  = 'phaseBonusGrid' + pad(turnIndex, 2) + symbDesc;
								r.push('<td>');
								showSymb(canvasIdStr, elementStr, colourWhite, colourBlack, symbDesc);
								r.push('</td>');

								symbDesc = bonusSymb;
								isPrizeCell = (symbBonusPrizes.indexOf(symbDesc) != -1);
								canvasIdStr = 'cvsBonusGridA' + pad(turnIndex, 2) + symbDesc;
								elementStr  = 'phaseBonusGridA' + pad(turnIndex, 2) + symbDesc;
								boxColourStr = (isPrizeCell) ? bonusBoxColours[symbBonusPrizes.indexOf(symbDesc)] : bonusSBoxColours[symbBonusWins.indexOf(symbDesc)];
								textColourStr = (isPrizeCell) ? colourBlack : bonusSTextColours[symbBonusWins.indexOf(symbDesc)];
								r.push('<td>');
								showSymb(canvasIdStr, elementStr, boxColourStr, textColourStr, symbDesc);
								r.push('</td>');

								for (var i = 0; i < bonusLetterCounts.length; i++)
								{
									symbDesc = bonusLetterCounts[i].toString();
									canvasIdStr = 'cvsBonusGridB' + pad(turnIndex, 2) + i.toString() + symbDesc;
									elementStr  = 'phaseBonusGridB' + pad(turnIndex, 2) + i.toString() + symbDesc;
									lastRow = (turnIndex == (scenarioBonus2.length -1));
									r.push('<td>');
									if (lastRow) 
									{
										boxColourStr = (parseInt(symbDesc, 10) > 0) ? colourYellow : ((i == bonusLetterCounts.length -1) ? colourYellow : colourWhite); 
									}
									else
									{
										boxColourStr = (i == colUpdated) ? colourMidGreen : colourWhite;
									}
									showSymb(canvasIdStr, elementStr, boxColourStr, colourBlack, symbDesc);
									r.push('</td>');
								}
								r.push('</tr>');
							}
							r.push('</table>');
							r.push('</div>');

							//////////////////
							// Bonus Prizes //
							//////////////////
							var bonusPrizeData = '';
							for (var i = 0; i < bonusLetterCounts.length -1; i++)
							{
								if (bonusLetterCounts[i] > 0)
								{	
									bonusPrizeData = String.fromCharCode(65 + i);
									bonusPrizes.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, 'g' + bonusPrizeData)]);
									bonusPrizeNames.push(bonusPrizeData);
									bonusPrizeQtys.push(bonusLetterCounts[i]);
								}
							}
							r.push('<p>&nbsp;</p>');
							showBonusTotal(bonusPrizes, bonusPrizeNames, bonusPrizeQtys, bonusLetterCounts[bonusLetterCounts.length -1]);
						}

						r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
	 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
 								r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getMainGameData(scenario)
					{
						return scenario.split("|")[0];
					}

					function getBonusData(scenario, part)
					{
						var scenarioData = scenario.split("|")[part];

						if (scenarioData != '')
						{
							return scenarioData;
						}

						return "";
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}
						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;
						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
				]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames),  $wageredPricePoint)" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
