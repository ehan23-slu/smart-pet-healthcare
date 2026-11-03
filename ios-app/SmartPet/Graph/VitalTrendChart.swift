import SwiftUI
import Charts

struct VitalTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum TrendRange: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
}

struct VitalTrendChart: View {

    let title: String
    let data: [VitalTrendPoint]
    let color: Color

    @State private var selectedRange: TrendRange = .day


    // MARK: - Filter data depending on 1D / 1W / 1M
    private var filteredData: [VitalTrendPoint] {

        guard let latestDate = data.map(\.date).max() else {
            return []
        }

        let calendar = Calendar.current

        let startDate: Date

        switch selectedRange {

        case .day:
            startDate = calendar.date(
                byAdding: .day,
                value: -1,
                to: latestDate
            )!

        case .week:
            startDate = calendar.date(
                byAdding: .day,
                value: -7,
                to: latestDate
            )!

        case .month:
            startDate = calendar.date(
                byAdding: .month,
                value: -1,
                to: latestDate
            )!
        }

        return data.filter {
            $0.date >= startDate &&
            $0.date <= latestDate
        }
    }


    // MARK: - Bottom of gradient area
    private var baseline: Double {

        guard let minimum = filteredData.map(\.value).min() else {
            return 0
        }

        let maximum = filteredData.map(\.value).max() ?? minimum

        let difference = maximum - minimum

        return minimum - max(difference * 0.2, 1)
    }


    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            // MARK: Header
            HStack {

                Text(title)
                    .font(.headline)

                Spacer()

                HStack(spacing: 2) {

                    ForEach(TrendRange.allCases, id: \.self) { range in

                        Button {

                            selectedRange = range

                        } label: {

                            Text(range.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    selectedRange == range
                                    ? .white
                                    : .secondary
                                )
                                .frame(width: 42, height: 26)
                                .background(
                                    selectedRange == range
                                    ? Color.gray
                                    : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(2)
                .background(
                    Color.gray.opacity(0.10)
                )
                .clipShape(Capsule())
            }


            // MARK: Chart
            Chart {

                // Gradient underneath line
                ForEach(filteredData) { point in

                    AreaMark(
                        x: .value("Time", point.date),
                        yStart: .value("Baseline", baseline),
                        yEnd: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                color.opacity(0.20),
                                color.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }


                // Main line
                ForEach(filteredData) { point in

                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 2
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }


                // Last data point
                if let lastPoint = filteredData.last {

                    PointMark(
                        x: .value("Time", lastPoint.date),
                        y: .value("Value", lastPoint.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(70)
                }
            }
            .chartXAxis {
                
                switch selectedRange {

                case .day:
                    // 1D: every 30 minutes
                    AxisMarks(
                        values: .stride(by: .minute, count: 30)
                    ) { value in

                        AxisGridLine()
                            .foregroundStyle(.clear)

                        AxisTick()
                            .foregroundStyle(.clear)

                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(
                                    date,
                                    format: .dateTime
                                        .hour()
                                        .minute()
                                )
                                .foregroundStyle(
                                    Color.gray.opacity(0.7)
                                )
                            }
                        }
                    }


                case .week:
                    // 1W: every day
                    AxisMarks(
                        values: .stride(by: .day)
                    ) { value in

                        AxisGridLine()
                            .foregroundStyle(.clear)

                        AxisTick()
                            .foregroundStyle(.clear)

                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(
                                    date,
                                    format: .dateTime
                                        .weekday(.abbreviated)
                                )
                                .foregroundStyle(
                                    Color.gray.opacity(0.7)
                                )
                            }
                        }
                    }


                case .month:
                    // 1M: every week
                    AxisMarks(
                        values: .stride(by: .day, count: 7)
                    ) { value in

                        AxisGridLine()
                            .foregroundStyle(.clear)

                        AxisTick()
                            .foregroundStyle(.clear)

                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(
                                    date,
                                    format: .dateTime
                                        .month(.abbreviated)
                                        .day()
                                )
                                .foregroundStyle(
                                    Color.gray.opacity(0.7)
                                )
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(
                    position: .leading,
                    values: .automatic(desiredCount: 5)
                ) {

                    AxisGridLine(
                        stroke: StrokeStyle(
                            lineWidth: 0.6,
                            dash: [4, 4]
                        )
                    )
                    .foregroundStyle(
                        Color.gray.opacity(0.25)
                    )

                    AxisTick()
                        .foregroundStyle(.clear)

                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            
            .frame(height: 170)
        }
        .padding(.horizontal)
    }
}
