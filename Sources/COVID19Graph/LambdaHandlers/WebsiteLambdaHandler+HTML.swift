extension WebsiteLambdaHandler {
    func html(_ data: WebsiteData) -> String {
        let prefectures = "[" + data.prefectureMaster.map { "'\($0)'" }.joined(separator: ",") + "]"
        let items = "[" + data.itemMaster.map { "'\($0)'" }.joined(separator: ",") + "]"
        let dataArray = "[" +
            data.data.map {
                "[\($0.map {"[\($0.map { "\($0)" }.joined(separator: ","))]" }.joined(separator: ",\n"))]"
            }.joined(separator: ",\n")
        + "]"
        return """
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>タイトル</title>
            
            <!-- Chart.js -->
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/chart.js@2.9.4/dist/Chart.min.css">
            <!-- Model -->
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/fancyapps/fancybox@3.5.7/dist/jquery.fancybox.min.css" />

          </head>
          <body>

            <!-- Model 表示ボタン -->
            <button data-fancybox data-src="#hidden-content" href="javascript:;">
                表示選択
            </button>
            
            <canvas id="\(myChartID)"></canvas>
            
            \(modal(data.prefectureMaster, data.itemMaster))
            
            <br>
            データは下記のものを利用させて頂いています。
            <p>東洋経済オンライン「新型コロナウイルス 国内感染の状況」制作：荻原和樹</p>
            <a href="https://github.com/kaz-ogiwara/covid19/">GitHubのソースコード</a>

            <!-- Chart.js -->
            <script src="https://cdn.jsdelivr.net/npm/chart.js@2.9.4/dist/Chart.min.js"></script>
            
            <!-- Modal -->
            <script src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.min.js"></script>
            <script src="https://cdn.jsdelivr.net/gh/fancyapps/fancybox@3.5.7/dist/jquery.fancybox.min.js"></script>

            <script type="text/javascript">
                const prefectures = \(prefectures);
                const items = \(items);
                const data = \(dataArray);

                const ctx = document.getElementById('\(myChartID)').getContext('2d');
        
                const configs = {
                    responsive: true,
                    title: {
                        display: true,
                        text: '新型コロナウイルスの現状',
                    },
                    layout: {
                        padding: {
                            left: 20,
                            right: 20,
                            top: 20,
                            bottom: 20
                        }
                    },
                    scales: {
                        xAxes: [
                            {
                                ticks: {
                                    autoSkip: true,
                                    // autoSkipPadding: 40,
                                    maxTicksLimit: 20,
                                },
                                offset: true,
                            },
                        ],
                        yAxes: [
                            {
                                id: "\(y1)",
                                type: "linear",
                                position: "left",
                                ticks: {
                                    beginAtZero: true
                                }
                            },
                            {
                                id: "\(y2)",
                                type: "linear",
                                position: "right",
                                ticks: {
                                    beginAtZero: true
                                },
                                gridLines: {
                                    drawOnChartArea: false,
                                },
                            }
                        ]
                    }
                };

                const mychart = new Chart(ctx, {
                    type: 'line',
                    options: configs
                });
                mychart.data.labels = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
                
                // labels: グラフごとのラベル
                // a: 元データ（月別、都道府県別、アイテム別（入院、死亡者数など））
                function getDatasets(isNew, selectedPrefectures, selectedItems, yAxisID) {
                    // 新規
                    if (isNew) {
                        return selectedPrefectures.map((i) => {
                            return selectedItems.map((j) => {
                                const _a = [...Array(data.length).keys()].map((k) => {
                                    return (k == 0 ? data[k][i][j] : data[k][i][j] - data[k - 1][i][j])
                                });
                                if (yAxisID == '\(y1)') {
                                    return {
                                        type: 'line',
                                        label: prefectures[i] + 'の' + items[j],
                                        pointRadius: 0,
                                        fill: false,
                                        borderColor: `rgb(${random()}, ${random()}, ${random()})`,
                                        data: _a,
                                        yAxisID: yAxisID
                                    }
                                } else {
                                    return {
                                        type: 'bar',
                                        label: prefectures[i] + 'の' + items[j],
                                        fill: true,
                                        borderColor: `rgb(${random()}, ${random()}, ${random()})`,
                                        backgroundColor: `rgb(${random()}, ${random()}, ${random()}, 0.2)`,
                                        data: _a,
                                        yAxisID: yAxisID
                                    }
                                }
                            });
                        })
                        .flat();
                    // 累計
                    } else {
                        return selectedPrefectures.map((i) => {
                            return selectedItems.map((j) => {
                                const _a = [...Array(data.length).keys()].map((k) => {
                                    return data[k][i][j];
                                });
                                if (yAxisID == '\(y1)') {
                                    return {
                                        type: 'line',
                                        label: prefectures[i] + 'の' + items[j],
                                        pointRadius: 0,
                                        fill: false,
                                        borderColor: `rgb(${random()}, ${random()}, ${random()})`,
                                        data: _a,
                                        yAxisID: yAxisID
                                    }
                                } else {
                                    return {
                                        type: 'bar',
                                        label: prefectures[i] + 'の' + items[j],
                                        fill: true,
                                        borderColor: `rgb(${random()}, ${random()}, ${random()})`,
                                        backgroundColor: `rgb(${random()}, ${random()}, ${random()}, 0.2)`,
                                        data: _a,
                                        yAxisID: yAxisID
                                    }
                                }
                            });
                        })
                        .flat();
                    }
                }

                function update() {
                    const isNewL = (getRadioValue('\(newOrTotalRadioNameL)') == 0 ? true : false)
                    const selectedPrefecturesL = getCheckBoxValue('\(prefectureCheckBoxNameL)')
                    const selectedItemL = getCheckBoxValue('\(itemCheckBoxNameL)')
                    const isNewR = (getRadioValue('\(newOrTotalRadioNameR)') == 0 ? true : false)
                    const selectedPrefecturesR = getCheckBoxValue('\(prefectureCheckBoxNameR)')
                    const selectedItemR = getCheckBoxValue('\(itemCheckBoxNameR)')
                    updateChart(isNewL, selectedPrefecturesL, selectedItemL, isNewR, selectedPrefecturesR, selectedItemR);
                }

                function updateChart(isNewL, selectedPrefecturesL, selectedItemL, isNewR, selectedPrefecturesR, selectedItemR) {
                    const dl = getDatasets(isNewL, selectedPrefecturesL, selectedItemL, '\(y1)');
                    const dr = getDatasets(isNewR, selectedPrefecturesR, selectedItemR, '\(y2)');
                    mychart.data.datasets = dl.concat(dr);
                    mychart.update();
                }
                
                function getRadioValue(name) {
                    const e = document.getElementsByName(name);
                    var z;
                    for (let i = 0; i < e.length; i++) {
                        if (e[i].checked) {
                            z = e[i].value;
                            break;
                        }
                    }
                    return z
                }

                function getCheckBoxValue(name) {
                    const e = document.getElementsByName(name);
                    return [...Array(e.length).keys()]
                    .filter((i) => {
                        return e[i].checked
                    })
                    .map((i) => {
                        return e[i].value
                    });
                }

                function random(max = 255, min = 100) {
                    return Math.floor( Math.random() * (max + 1 - min) ) + min;
                }

            </script>
          </body>
        </html>
        """
    }
    
    private var myChartID: String { "myChart" }
    
    private var y1: String { "y1" }
    private var y2: String { "y2" }
    
    private var newOrTotalRadioNameL: String { "newOrTotalRadioL" }
    private var prefectureCheckBoxNameL: String { "prefectureCheckBoxL" }
    private var itemCheckBoxNameL: String { "itemCheckBoxL" }
    
    private var newOrTotalRadioNameR: String { "newOrTotalRadioR" }
    private var prefectureCheckBoxNameR: String { "prefectureCheckBoxR" }
    private var itemCheckBoxNameR: String { "itemCheckBoxR" }
    
    private func modal(
        _ prefectures: [String],
        _ items: [String]
    ) -> String {
        let f = { (rn: String, pn: String, in: String) -> String in
            let prefectures = prefectures.enumerated().map {
                let s = "<input type=\"checkbox\" name=\"\(pn)\" value=\"\($0.offset)\">\($0.element)"
                return $0.offset > 0 && $0.offset % 5 == 0 ? s + "<br>" : s
            }
            .joined(separator: "\n")
            
            let items = items.enumerated().map {
                let s = "<input type=\"checkbox\" name=\"\(`in`)\" value=\"\($0.offset)\">\($0.element)"
                return $0.offset > 0 && $0.offset % 3 == 0 ? s + "<br>" : s
            }
            .joined(separator: "\n")
            
            return """
                <p>
                    <input type="radio" name="\(rn)" value="0" checked="checked">新規
                    <input type="radio" name="\(rn)" value="1">累計
                </p>
                
                <p>＊都道府県</p>
                \(prefectures)
                
                <p>＊項目</p>
                \(items)
            """
        }
        
        return
            """
            <div style="display: none;" id="hidden-content">
                <h3>表示データ選択</h3>
                
                <p>== 左側Y軸 ==</p>
                \(f(newOrTotalRadioNameL, prefectureCheckBoxNameL, itemCheckBoxNameL))
                
                <br><hr><hr><br>

                <p>== 右側Y軸 ==</p>
                \(f(newOrTotalRadioNameR, prefectureCheckBoxNameR, itemCheckBoxNameR))
                    
                <br><br><br>

                <div>
                    <button data-fancybox-close onclick="update();">決定</button>
                    <button data-fancybox-close>キャンセル</button>
                </div>
            </div>
            """
    }
    
}
