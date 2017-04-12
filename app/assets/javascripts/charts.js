function createMapChart(div, title, win, lose, draw) {
    return Highcharts.chart(div, {
        chart: {
            type: 'pie',
            options3d: {
                enabled: true,
                alpha: 45,
                beta: 0
            }
        },
        title: {
            text: title,
            margin: 0,
            style: {
                fontSize: "13px"
            }
        },
        tooltip: {
            pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
        },
        plotOptions: {
            pie: {
                allowPointSelect: true,
                cursor: 'pointer',
                depth: 35,
                dataLabels: {
                    enabled: false,
                    format: '{point.name}'
                }
            }
        },
        series: [{
            type: 'pie',
            name: 'Match Result',
            data: [
                ['Draw', draw],
                ['Lose', lose],
                ['Win', win]
            ]
        }]
    });
}
