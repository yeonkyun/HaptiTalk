// canvas 모듈 의존성 문제로 인해 임시 대체 모듈
// const { ChartJSNodeCanvas } = require('chartjs-node-canvas');

// 차트 캔버스 설정 (실제 생성하지 않고 더미 데이터 반환)
const width = 800;
const height = 600;
// const chartCanvas = new ChartJSNodeCanvas({ width, height, backgroundColour: 'white' });

const chartsUtils = {
    /**
     * 차트 설정을 기반으로 이미지 생성 (임시 대체 함수)
     */
    async generateChartImage(chartConfig) {
        try {
            // 실제 차트를 생성하지 않고 더미 버퍼 반환
            const dummyBuffer = Buffer.from('Chart generation disabled');
            return dummyBuffer;
        } catch (error) {
            throw new Error(`Chart generation error: ${error.message}`);
        }
    },

    /**
     * 여러 차트를 하나의 데이터셋으로 결합
     */
    combineChartData(datasets, labels) {
        return {
            labels,
            datasets
        };
    },

    /**
     * 시계열 데이터를 라인 차트용으로 변환
     */
    formatTimelineData(timeline, metricPath, label, color) {
        // 점으로 구분된 경로를 따라 객체의 깊은 속성에 접근
        const getNestedValue = (obj, path) => {
            return path.split('.').reduce((prev, curr) =>
                prev && prev[curr] !== undefined ? prev[curr] : null, obj);
        };

        return {
            label,
            data: timeline.map(point => getNestedValue(point, metricPath) || 0),
            borderColor: color,
            backgroundColor: color.replace(')', ', 0.1)').replace('rgb', 'rgba'),
            fill: false
        };
    },

    /**
     * 표준 차트 옵션 생성
     */
    getChartOptions(title, xTitle, yTitle) {
        return {
            responsive: true,
            plugins: {
                title: {
                    display: !!title,
                    text: title
                },
                legend: {
                    position: 'top',
                }
            },
            scales: {
                x: {
                    title: {
                        display: !!xTitle,
                        text: xTitle
                    }
                },
                y: {
                    title: {
                        display: !!yTitle,
                        text: yTitle
                    }
                }
            }
        };
    }
};

module.exports = chartsUtils;