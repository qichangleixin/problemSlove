   //视频监控
        function showVideo(dev_id){
            var	height=($(window).height() );
            	if(height>544) {
            	  height=544;
            	}
	            layer.open({
				    type: 2,
				    title: '监控视频',
			      	shadeClose: true,
				    shade : 0.4,
				    maxmin: true,
				    area : [ '967px', height+"px" ],
				    content: '<%=path%>/eventHandleAction/showVideo?dev_id='+dev_id,
				    moveEnd: function(layero){
					   	var offsetLeft=layero.find('iframe')["prevObject"][0].offsetLeft
					   	var iframeWin = layero.find('iframe')[0];
					   	postScrollEvent();
					   	function postScrollEvent(){
			        		// 计算滚动条偏移量
			        		var scrollLeftValue = document.documentElement.scrollLeft;
			        		var scrollTopValue = document.documentElement.scrollTop;
			        		iframeWin.contentWindow.postMessage({
			        			  action:'scroll',        
			        			  msg: 'scroll事件',	 						  
			        			  scrollValue: {          // 滚动条滚动的偏移量
			        					left: -1 * scrollLeftValue,
			        					top: -1 * scrollTopValue,									
			        				  },
			        				iframeClientPos: {	  // iframe相对视窗的位置
			        					left: iframeWin.getBoundingClientRect().left,
			        					right: iframeWin.getBoundingClientRect().right,
			        					top: iframeWin.getBoundingClientRect().top,
			        					bottom: iframeWin.getBoundingClientRect().bottom
			        				},
			        				showSize: {          // 告诉嵌入的子页面视窗高度与宽度
			        					width: $(window).width(),    // 视窗宽度
			        					height: $(window).height()  // 视窗高度
			        				},
			        				iframeOffset: {      // iframe偏离文档的位置
			        					left: layero.find('iframe')["prevObject"][0].offsetLeft,
			        					top: 123									
			        				  }
			        			}, '\*');	   // '\*'表示跨域参数，请结合自身业务合理设置
			        	}
				    },
				    success: function(layero, index){
					   //var iframeWin = window[layero.find('iframe')[0]['name']]; //得到iframe页的窗口对象，执行iframe页的方法：iframeWin.method();
					   var offsetLeft=layero.find('iframe')["prevObject"][0].offsetLeft
						console.log(layero.find('iframe'))
					   var iframeWin = layero.find('iframe')[0];  
					   {

						 		iframeWin.contentWindow.postMessage({
						 							  action:'sendTitle',   // 告诉子页面本页面的标题（action自行指定，但需要与子页面中监听的action保持一致
						 							  msg: '将标题发给子页面',
						 							  info: document.title
						 							}, '\*');
						 		iframeWin.contentWindow.postMessage({
						 							  action:'updateInitParam',    // 告诉子页面一些初始值，包括浏览器视窗高度与宽度、iframe偏离文档的位置、iframe相对视窗的位置
						 							  msg: '更新子页面一些初始值',
						 							  showSize: {                       // 浏览器视窗高度与宽度
						 									width: $(window).width(),  
						 									height: $(window).height()  
						 								},
						 							  iframeOffset: {                   // iframe偏离文档的位置
						 									left: offsetLeft,
						 									top: 138
						 								  }, 
					 								 /* iframeOffset: {                   // iframe偏离文档的位置
						 									left: iframeWin.offsetLeft,
						 									top: iframeWin.offsetTop    
						 								  }, */
						 							  iframeClientPos: {	            // iframe相对视窗的位置
						 									left: iframeWin.getBoundingClientRect().left,
						 									right: iframeWin.getBoundingClientRect().right,
						 									top: iframeWin.getBoundingClientRect().top,
						 									bottom: iframeWin.getBoundingClientRect().bottom
						 								}
						 							}, '\*');   // '\*'表示跨域参数，请结合自身业务合理设置
					 		
					 	}
					   //iframeWin.contentWindow.playBtn();
					  // 步骤3：监听嵌入子页面的事件
				        	window.addEventListener('message', function(e){
				        		console.log(e.data.msg);
				        		if(e && e.data){
				        			switch (e.data.action){
				        				case 'updateTitle':        // 本页面收到子页面通知更新标题通知，更新本页面标题
				        					document.title = e.data.info;
				        					break;
				        				case 'updatePos':
				        					var scrollLeftValue = document.documentElement.scrollLeft;
				        					var scrollTopValue = document.documentElement.scrollTop;
				        					iframeWin.contentWindow.postMessage({
				        							  action:'updatePos',  
				        							  msg: '更新Pos',
				        							  scrollValue: {          // 滚动条滚动的偏移量
				        									left: -1 * scrollLeftValue,
				        									top: -1 * scrollTopValue,									
				        								  }
				        							}, '\*');   // '\*'表示跨域参数，请结合自身业务合理设置
				        					break;
				        				default:
				        					break;
				        			}
				        		}
				        	});	
				            
				        	// 步骤4：兼听本页面的resize事件，并将一些状态值发送给嵌入的子页面
				        	var resizeTimer = null;
				        	var resizeDate;
				        	$(window).resize(function () {
				        		resizeDate = new Date();
				        		if (resizeTimer === null){
				        			resizeTimer = setTimeout(checkResizeEndTimer, 100);
				        		}
				        	});
				        	
				        	function checkResizeEndTimer(){
				        		if (new Date() - resizeDate > 100){  // resize结束后再发消息，避免残影问题
				        			clearTimeout(resizeTimer);
				        			resizeTimer = null;
				        			postResizeEvent();
				        		} else{
				        			setTimeout(checkResizeEndTimer, 100);
				        		}
				        	}
				        	
				        	function postResizeEvent(){
				        		var scrollLeftValue = document.documentElement.scrollLeft;
				        		var scrollTopValue = document.documentElement.scrollTop;
								
				        		iframeWin.contentWindow.postMessage({
				        					action: 'resize',       
				        					msg: 'resize事件',
				        					showSize: {             // 告诉嵌入的子页面视窗高度与宽度
				        						width: $(window).width(),   
				        						height: $(window).height()  
				        					},
				        					iframeClientPos: {	    // iframe相对视窗的位置
				        						left: iframeWin.getBoundingClientRect().left,
				        						right: iframeWin.getBoundingClientRect().right,
				        						top: iframeWin.getBoundingClientRect().top,
				        						bottom: iframeWin.getBoundingClientRect().bottom
				        					},
				        					scrollValue: {          // 滚动条滚动的偏移量
					        					left: -1 * scrollLeftValue,
					        					top: -1 * scrollTopValue,									
					        				},
				        					iframeOffset: {        // iframe偏离文档的位置
				        						left: layero.find('iframe')["prevObject"][0].offsetLeft,
				        						top: 138								
				        					  }
				        				}, '\*');     // '\*'表示跨域参数，请结合自身业务合理设置
				        	}

				        	// 步骤5：兼听本页面的scroll事件，并将一些状态值发送给嵌入的子页面
				        	// 为性能考虑，可以在定时器中处理
				        	var scrollTimer = null;
				        	var scrollDate;
				        	$(window).scroll(function (event) {
				        		postScrollEvent();
				        		scrollDate = new Date();
				        		if (scrollTimer === null){
				        			scrollTimer = setTimeout(checkScrollEndTimer, 100);
				        		}		
				            });	
				        	
				        	function checkScrollEndTimer(){
				        		if (new Date() - scrollDate > 100){  // resize结束后再发消息，避免残影问题
				        			clearTimeout(scrollTimer);
				        			scrollTimer = null;			
				        		} else{
				        			postScrollEvent();
				        			setTimeout(checkScrollEndTimer, 100);
				        		}
				        	}
				        	
				        	function postScrollEvent(){
				        		// 计算滚动条偏移量
				        		var scrollLeftValue = document.documentElement.scrollLeft;
				        		var scrollTopValue = document.documentElement.scrollTop;
				        		iframeWin.contentWindow.postMessage({
				        			  action:'scroll',        
				        			  msg: 'scroll事件',	 						  
				        			  scrollValue: {          // 滚动条滚动的偏移量
				        					left: -1 * scrollLeftValue,
				        					top: -1 * scrollTopValue,									
				        				  },
				        				iframeClientPos: {	  // iframe相对视窗的位置
				        					left: iframeWin.getBoundingClientRect().left,
				        					right: iframeWin.getBoundingClientRect().right,
				        					top: iframeWin.getBoundingClientRect().top,
				        					bottom: iframeWin.getBoundingClientRect().bottom
				        				},
				        				showSize: {          // 告诉嵌入的子页面视窗高度与宽度
				        					width: $(window).width(),    // 视窗宽度
				        					height: $(window).height()  // 视窗高度
				        				},
				        				iframeOffset: {      // iframe偏离文档的位置
				        					left: layero.find('iframe')["prevObject"][0].offsetLeft,
				        					top: iframeWin.offsetTop									
				        				  }
				        			}, '\*');	   // '\*'表示跨域参数，请结合自身业务合理设置
				        	}
					},
				    cancel: function(index, layero){
					     var iframeWin = window[layero.find('iframe')[0]['name']]; //得到iframe页的窗口对象，执行iframe页的方法：iframeWin.method();
					}
				});
            }
