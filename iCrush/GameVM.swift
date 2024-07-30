//
//  GameVM.swift
//  iCrush
//
//  Created by Yery Castro on 16/7/24.
//

import SwiftUI

@Observable
class GameVM {
    var score = 0
    var combo = 0
    
    var isMatch = false
    var isProcessing = false
    var gameTime = 30
    var isPlaying = false
    var isStop = false
    var timer: Timer?
    var rows = 8
    var columns = 8
    var board: [[IconType]] = Array(repeating: Array(repeating: IconType.empty, count: 8), count: 8)
    var firstButtonPressed: (row: Int, col: Int)? = nil
    var secondButtonPressed: (row: Int, col: Int)? = nil
    var bestScore: Int = UserDefaults.standard.integer(forKey: "bestScore")
    
    func fillGrid() {
        for row in 0..<rows {
            for col in 0..<columns {
                withAnimation(.easeInOut(duration: 0.3)) {
                    board[row][col] = IconType.random()
                }
            }
        }
    }
    
    func preventInitialMatches() {
       var hasMadeChanges = true
        while hasMadeChanges {
            hasMadeChanges = false
            for row in 0..<rows {
                for col in 0..<columns {
                    let current = board[row][col]
                    if hasMatch(row: row, col: col, type: current) {
                        board[row][col] = IconType.core().first {
                            $0 != current
                        } ?? .empty
                        hasMadeChanges = true
                    }
                }
            }
        }
    }
    
    func hasMatch(row: Int, col: Int, type: IconType) -> Bool {
        if(col >= 2 && board[row][col - 1] == type && board[row][col - 2] == type) || (col < columns - 2 && board[row][col + 1] == type && board[row][col + 2] == type) {
            return true
        }
        if(row >= 2 && board[row - 1][col] == type && board[row - 2][col] == type) || (row < rows - 2 && board[row + 1][col] == type && board[row + 2][col] == type) {
            return true
        }
        return false
    }
    
    func setupBoard() {
        self.board = Array(repeating: Array(repeating: IconType.empty, count: 8), count: 8)
        withAnimation(.easeInOut(duration: 0.3)) {
            fillGrid()
            preventInitialMatches()
        }
    }
    
    func timerStop() {
        isStop = true
        timer?.invalidate()
        timer = nil
    }
    
    func timerStart() {
        isStop = false
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.gameTime -= 1
            if (self.gameTime == 0) {
                self.timer?.invalidate()
                self.timer = nil
                self.isPlaying = false
            }
        }
    }
    
    func gameStart() {
        self.score = 0
        self.gameTime = 30
        isPlaying = true
        self.timerStart()
        setupBoard()
    }
    
    func markMatches(checkList: inout [[Bool]]) {
        for row in 0..<rows {
            for col in 0..<(columns - 2) {
                let type = board[row][col]
                if type != .empty && IconType.core().contains(type) && board[row][col + 1] == type && board[row][col + 2] == type {
                    checkList[row][col] = true
                    checkList[row][col + 1] = true
                    checkList[row][col + 2] = true
                    isMatch = true
                }
            }
        }
        
        for row in 0..<(rows - 2) {
            for col in 0..<columns {
                let type = board[row][col]
                if type != .empty && IconType.core().contains(type) && board[row + 1][col] == type && board[row + 2][col] == type {
                    checkList[row][col] = true
                    checkList[row + 1][col] = true
                    checkList[row + 2][col] = true
                    isMatch = true
                }
            }
        }
    }
    
    func checkDead() -> Bool {
        for row in board {
            for cell in row {
                switch cell {
                    
                case .row, .column, .bomb, .gift, .bang:
                    return false
                default:
                    continue
                }
            }
        }
        
        for row in 0..<rows {
            for col in 0..<columns {
                let type = board[row][col]
                if col < columns - 1 && IconType.core().contains(type) && IconType.core().contains(board[row][col + 1]) {
                    if(col > 0 && IconType.core().contains(board[row][col - 1])) || (col < columns - 2 && IconType.core().contains(board[row][col + 2])) {
                        return true
                    }
                }
                
                if row < rows - 1 && IconType.core().contains(type) && IconType.core().contains(board[row + 1][col]) {
                    if(row > 0 && IconType.core().contains(board[row - 1][col])) || (row < rows - 2 && IconType.core().contains(board[row + 2][col])) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func clearAll() {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            board = Array(repeating: Array(repeating: IconType.empty, count: 8), count: 8)
        }
        score += 50
        combo += 2
        extendTimerBasedOnScore()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fall()
        }
    }
    
    func runFunctionWithDelay(delay: TimeInterval, functionToRun: @escaping () -> Void) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            functionToRun()
        }
    }
    
    func checkAndMarkSpecialMatches(checkList: inout [[Bool]]) {
        for column in 0..<columns {
            var matchLength = 0
            for row in 0..<rows {
                if checkList[row][column] {
                    matchLength += 1
                } else {
                    if matchLength >= 5 {
                        clearCheckListVertical(fromRow: row - matchLength, toRow: row - 1, column: column, checkList: &checkList)
                        setSpecialCellVertical(fromRow: row - matchLength, toRow: row - 1, column: column)
                        
                    }
                    matchLength = 0
                }
            }
            if matchLength >= 5 {
                clearCheckListVertical(fromRow: rows - matchLength, toRow: rows - 1, column: column, checkList: &checkList)
                setSpecialCellVertical(fromRow: rows - matchLength, toRow: rows - 1, column: column)
            }
        }
        for row in 0..<rows {
            var matchLength = 0
            for column in 0..<columns {
                if checkList[row][column] {
                    matchLength += 1
                } else {
                    if matchLength >= 5 {
                        clearCheckListHorizontal(fromColumn: column - matchLength, toColumn: column - 1, row: row, checkList: &checkList)
                        setSpecialCellHorizontal(fromColumn: column - matchLength, toColumn: column - 1, row: row)
                        
                    }
                    matchLength = 0
                }
            }
            
            if matchLength >= 5 {
                clearCheckListHorizontal(fromColumn: columns - matchLength, toColumn: columns - 1, row: row, checkList: &checkList)
            }
        }
        
    }
    
    func setSpecialCellHorizontal(fromColumn: Int, toColumn: Int, row: Int) {
        withAnimation(.easeInOut(duration: 0.4)) {
            for col in fromColumn..<toColumn {
                board[row][col] = .empty
            }
            board[row][toColumn] = .gift
        }
    }
    
    func clearCheckListHorizontal(fromColumn: Int, toColumn: Int, row: Int, checkList: inout [[Bool]]) {
        for column in fromColumn...toColumn {
            checkList[row][column] = false
        }
    }
    
    func setSpecialCellVertical(fromRow: Int, toRow: Int, column: Int) {
        withAnimation(.easeInOut(duration: 0.4)) {
            for row in fromRow..<toRow {
                board[row][column] = .empty
            }
            board[toRow][column] = .gift
        }
    }
    
    func clearCheckListVertical(fromRow: Int, toRow: Int, column: Int, checkList: inout [[Bool]]) {
        for row in fromRow...toRow {
            checkList[row][column] = false
        }
    }
    
    func markFourMatches(checkList: inout [[Bool]]) {
        for row in 0..<rows {
            for column in 0..<(columns - 3) {
                if checkList[row][column] && board[row][column] == board[row][column + 1] && board[row][column] == board[row][column + 2] && board[row][column] == board[row][column + 3] && IconType.core().contains(board[row][column]) {
                    for i in 0..<4 {
                        checkList[row][column + i] = false
                        board[row][column + i] = .empty
                    }
                    
                    withAnimation(.easeInOut(duration: 0.4)) {
                        board[row][column] = .row
                    }
                }
            }
        }
        
        for row in 0..<(rows - 3) {
            for column in 0..<columns {
                if checkList[row][column] && board[row][column] == board[row + 1][column] && board[row][column] == board[row + 2][column] && board[row][column] == board[row + 3][column] && IconType.core().contains(board[row][column]) {
                    for i in 0..<4 {
                        checkList[row + i][column] = false
                        board[row + 1][column] = .empty
                    }
                    
                    withAnimation(.easeInOut(duration: 0.4)) {
                        board[row][column] = .column
                    }
                }
            }
        }
        
    }
    
    func processThreeMatches(checkList: inout [[Bool]]) {
        for row in 0..<rows {
            for column in 0..<(columns - 2) {
                if checkList[row][column] && board[row][column] == board[row][column + 1] && board[row][column] == board[row][column + 2] && IconType.core().contains(board[row][column]) {
                    for i in 0..<3 {
                        checkList[row][column + i] = false
                        board[row][column + i] = .empty
                    }
                    score += 3
                    combo += 1
                    extendTimerBasedOnScore()
                }
            }
        }
        
        for row in 0..<(rows - 2) {
            for column in 0..<columns {
                if checkList[row][column] && board[row][column] == board[row + 1][column] && board[row][column] == board[row + 2] [column] && IconType.core().contains(board[row][column]) {
                    for i in 0..<3 {
                        checkList[row + i][column] = false
                        board[row + 1][column] = .empty
                    }
                }
            }
        }
    }
    
    func markLShapedMatchesAsEspecial(checkList: inout [[Bool]]) {
        for row in 0..<rows {
            for column in 0..<columns {
                if !checkList[row][column] {
                    continue
                }
                let centerType = board[row][column]
                let positionOne = [(row, column), (row, column - 1), (row, column - 2), (row - 1, column), (row - 2, column)]
                let positionTwo = [(row, column), (row, column + 1), (row, column + 2), (row - 1, column), (row - 2, column)]
                let positionThree = [(row, column), (row, column + 1), (row, column + 2), (row + 1, column), (row + 2, column)]
                let positionFour = [(row, column), (row, column - 1), (row, column - 2), (row + 1, column), (row + 2, column)]
                
                func isLShape(positions: [(Int, Int)]) -> Bool {
                    for position in positions {
                        if position.0 < 0 || position.0 >= rows || position.1 < 0 || position.1 >= columns || board[position.0][position.1] != centerType || !checkList[position.0][position.1] {
                            return false
                        }
                    }
                    return true
                }
                
                let isLShapeOne = isLShape(positions: positionOne)
                let isLShapeTwo = isLShape(positions: positionTwo)
                let isLShapeThree = isLShape(positions: positionThree)
                let isLShapeFour = isLShape(positions: positionFour)
                
                if isLShapeOne || isLShapeTwo || isLShapeThree || isLShapeFour {
                    [positionOne, positionTwo, positionThree, positionFour].forEach { positions in
                        positions.forEach { position in
                            if position.0 >= 0 && position.0 < rows && position.1 >= 0 && position.1 < columns {
                                checkList[position.0][position.1] = false
                                board[position.0][position.1] = .empty
                            }
                        }
                    }
                    
                    withAnimation(.easeInOut(duration: 0.4)) {
                        board[row][column] = .bomb
                    }
                }
            }
        }
    }
    
    func clear(checkList: inout [[Bool]]) {
        for row in 0..<rows {
            for column in 0..<columns {
                if checkList[row][column] == true {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        board[row][column] = .empty
                    }
                }
                checkList[row][column] = false
            }
        }
    }
    
    func checkMatch() {
        var checkList = Array(repeating: Array(repeating: false, count: columns), count: rows)
        withAnimation(.easeInOut(duration: 0.5)) {
            markMatches(checkList: &checkList)
            checkAndMarkSpecialMatches(checkList: &checkList)
            markLShapedMatchesAsEspecial(checkList: &checkList)
            markFourMatches(checkList: &checkList)
            processThreeMatches(checkList: &checkList)
            clear(checkList: &checkList)
            if isMatch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.fall()
                    self.isProcessing = false
                }
            } else {
                if checkDead() {
                    board.shuffle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.fall()
                    }
                }
                isProcessing = false
            }
        }
    }
    
    func fall() {
        var didChange: Bool
        repeat {
            didChange = false
            for row in 1..<rows {
                for col in 0..<columns {
                    if board[row][col] == .empty && board[row - 1][col] != .empty {
                        (board[row][col], board[row - 1][col]) = (board[row - 1][col], board[row][col])
                        didChange = true
                    }
                }
            }
            for col in 0..<columns where board[0][col] == .empty {
                board[0][col] = IconType.random()
                didChange = true
            }
        } while didChange
                    isMatch = false
                    runFunctionWithDelay(delay: 0.3) {
            self.checkMatch()
        }
    }
    
    func bomb(rowIndex: Int, columnIndex: Int) {
        isMatch = true
        withAnimation(.easeOut(duration: 0.4)) {
            board[rowIndex][columnIndex] = .empty
        }
        score += 10
        combo += 1
        extendTimerBasedOnScore()
        
        handleAdjacentCell(rowIndex: rowIndex - 1, columnIndex: columnIndex)
        handleAdjacentCell(rowIndex: rowIndex + 1, columnIndex: columnIndex)
        handleAdjacentCell(rowIndex: rowIndex, columnIndex: columnIndex - 1)
        handleAdjacentCell(rowIndex: rowIndex, columnIndex: columnIndex + 1)
        handleAdjacentCell(rowIndex: rowIndex - 1, columnIndex: columnIndex - 1)
        handleAdjacentCell(rowIndex: rowIndex + 1, columnIndex: columnIndex - 1)
        handleAdjacentCell(rowIndex: rowIndex + 1, columnIndex: columnIndex + 1)
        handleAdjacentCell(rowIndex: rowIndex + 1, columnIndex: columnIndex - 1)
    }
    
    func handleAdjacentCell(rowIndex: Int, columnIndex: Int) {
        guard rowIndex >= 0, rowIndex < rows, columnIndex >= 0, columnIndex < columns else {
            return
        }
        
        let cell = board[rowIndex][columnIndex]
        switch cell {
        case .bomb:
            self.bomb(rowIndex: rowIndex, columnIndex: columnIndex)
        case .empty:
            break
        case .row:
            self.rowActivate(rowIndex: rowIndex, colIndex: columnIndex)
        case .column:
            self.colActivate(rowIndex: rowIndex, colIndex: columnIndex)
        case .bang:
            break
        case .gift:
            self.gift(rowIndex: rowIndex, colIndex: columnIndex, icon: IconType.random())
        default:
            withAnimation {
                board[rowIndex][columnIndex] = .empty
            }
        }
        withAnimation(.easeOut(duration: 0.4)) {
            fall()
        }
    }
    
    func multiRow(firstRowIndex: Int, firstColIndex: Int, secondRowIndex: Int, secondColIndex: Int) {
        isMatch = true
        withAnimation(.easeOut(duration: 0.4)) {
            board[firstRowIndex][firstColIndex] = .empty
            board[secondRowIndex][secondColIndex] = .empty
        }
        let random = IconType.random()
        for row in 0..<rows {
            for col in 0..<columns {
                if board[row][col] == random {
                    board[row][col] = .row
                }
            }
        }
        
        for row in 0..<rows {
            for col in 0..<columns {
                if board[row][col] == .row {
                    self.rowActivate(rowIndex: row, colIndex: col)
                }
            }
        }
        score += 25
        combo += 2
        extendTimerBasedOnScore()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fall()
        }
    }
    
    func rowActivate(rowIndex: Int, colIndex: Int) {
        isMatch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            board[rowIndex][colIndex] = .empty
        }
        score += 5
        combo += 1
        extendTimerBasedOnScore()

        for col in 0..<columns {
            let cell = board[rowIndex][col]
            switch cell {
                
            case .empty:
                break
            case .row:
                break
            case .column:
                self.colActivate(rowIndex: rowIndex, colIndex: col)
            case .bang:
                break
            case .bomb:
                self.bomb(rowIndex: rowIndex, columnIndex: col)
            case .gift:
                self.gift(rowIndex: rowIndex, colIndex: col, icon: IconType.random())
            default:
                withAnimation {
                    board[rowIndex][col] = .empty
                }
            }
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            fall()
        }
    }
    
    func colActivate(rowIndex: Int, colIndex: Int) {
        isMatch = true
        withAnimation(.easeOut(duration: 0.4)) {
            board[rowIndex][colIndex] = .empty
        }
        score += 5
        combo += 1
        
        for row in 0..<rows {
            let cell = board[row][colIndex]
            switch cell {
                
            case .empty:
                break
            case .row:
                self.rowActivate(rowIndex: row, colIndex: colIndex)
            case .column:
                break
            case .bang:
                break
            case .bomb:
                self.bomb(rowIndex: row, columnIndex: colIndex)
            case .gift:
                self.gift(rowIndex: row, colIndex: colIndex, icon: IconType.random())
            default:
                withAnimation(.easeInOut(duration: 0.4)) {
                    board[row][colIndex] = .empty
                }
            }
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            fall()
        }
    }
    
    func multiCol(firstRowIndex: Int, firstColIndex: Int, secondRowIndex: Int, secondColIndex: Int) {
        isMatch = true
        withAnimation(.easeOut(duration: 0.4)) {
            board[firstRowIndex][firstColIndex] = .empty
            board[secondRowIndex][secondColIndex] = .empty
        }
        
        let random = IconType.random()
        for row in 0..<rows {
            for col in 0..<columns {
                if board[row][col] == random {
                    board[row][col] = .column
                }
            }
        }
        
        for row in 0..<rows {
            for col in 0..<columns {
                if board[row][col] == .column {
                    self.colActivate(rowIndex: row, colIndex: col)
                }
            }
        }
        score += 25
        combo += 2
        extendTimerBasedOnScore()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fall()
        }
    }
    
    func multiBomb(firstRowIndex: Int, firstColIndex: Int, secondRowIndex: Int, secondColIndex: Int) {
        isMatch = true
        withAnimation(.easeOut(duration: 0.4)) {
            board[firstRowIndex][firstColIndex] = .empty
            board[secondRowIndex][secondColIndex] = .empty
        }
        
        let random = IconType.random()
        for row in 0..<rows {
            for col in 0..<columns {
                if board[row][col] == random {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        board[row][col] = .bomb
                    }
                }
            }
        }
        
        for row in 0..<rows {
            for col in 0..<columns {
                if board[row][col] == .bomb {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.bomb(rowIndex: row, columnIndex: col)
                    }
                }
            }
        }
        score += 30
        combo += 2
        extendTimerBasedOnScore()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fall()
        }
    }
    
    func gift(rowIndex: Int, colIndex: Int, icon: IconType) {
        isMatch = true
        board[rowIndex][colIndex] = .empty
        score += 25
        combo += 1
        extendTimerBasedOnScore()
        for row in 0..<rows {
            for col in 0..<columns {
                if board[row][col] == icon {
                    withAnimation(.easeIn(duration: 0.4)){
                        board[row][col] = .empty
                    }
                }
            }
        }
    }
    
    func cross(firstRowIndex: Int, firstColIndex: Int, secondRowIndex: Int, secondColIndex: Int) {
        isMatch = true
        board[firstRowIndex][firstColIndex] = .empty
        board[secondRowIndex][secondColIndex] = .empty
        self.rowActivate(rowIndex: firstRowIndex, colIndex: firstColIndex)
        self.colActivate(rowIndex: firstRowIndex, colIndex: firstColIndex)
        withAnimation(.easeInOut(duration: 0.4)) {
            fall()
        }
        self.rowActivate(rowIndex: secondRowIndex, colIndex: secondColIndex)
        self.colActivate(rowIndex: secondRowIndex, colIndex: secondColIndex)
        score += 20
        combo += 1
        extendTimerBasedOnScore()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fall()
        }
    }
    
    func bigCross(firstRowIndex: Int, firstColIndex: Int, secondRowIndex: Int, secondColIndex: Int) {
        isMatch = true
        func indicesToClear(index: Int) -> [Int] {
            let possibleIndices = [index - 1, index + 1]
            return possibleIndices.filter {
                $0 >= 0 && $0 < 8
            }
        }
        
        let firstRowTocClear = indicesToClear(index: firstRowIndex)
        let firstColToClear = indicesToClear(index: firstColIndex)
        
        for row in firstRowTocClear {
            self.rowActivate(rowIndex: row, colIndex: firstColIndex)
        }
        for col in firstColToClear {
            self.colActivate(rowIndex: firstRowIndex, colIndex: col)
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            fall()
        }
        let secondRowToClear = indicesToClear(index: secondRowIndex)
        let secondColToClear = indicesToClear(index: secondColIndex)
        for row in secondRowToClear {
            self.rowActivate(rowIndex: row, colIndex: secondColIndex)
        }
        for col in secondColToClear {
            self.colActivate(rowIndex: secondRowIndex, colIndex: col)
        }
        score += 25
        combo += 1
        extendTimerBasedOnScore()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.fall()
        }
    }
    
    func tryProcess(row: Int, col: Int) {
        if firstButtonPressed == nil {
            firstButtonPressed = (row, col)
        } else if secondButtonPressed == nil {
            secondButtonPressed = (row, col)
            if let (rowOrigin, colOrigin) = firstButtonPressed, let (rowDestination, colDestination) = secondButtonPressed {
                process(rowOrigin: rowOrigin, colOrigin: colOrigin, rowDestination: rowDestination, colDestination: colDestination)
            }
            firstButtonPressed = nil
            secondButtonPressed = nil
        }
    }
    func process(rowOrigin: Int, colOrigin: Int, rowDestination: Int, colDestination: Int) {
        guard !isProcessing else { return }
        isMatch = false
        isProcessing = true
        if( abs(rowOrigin - rowDestination) == 1 && colOrigin == colDestination) ||
            (abs(colOrigin - colDestination) == 1 && rowOrigin == rowDestination) {
            withAnimation(.easeInOut(duration: 0.4)) {
                (board[rowOrigin][colOrigin], board[rowDestination][colDestination]) = (board[rowDestination][colDestination], board[rowOrigin][colOrigin])
            }
            let left = board[rowOrigin][colOrigin], right = board[rowDestination][colDestination]
            if [left, right].allSatisfy({
                $0 == .gift
            }) {
                clearAll()
            } else if left == .gift && right == .bomb || left == .bomb && right == .gift {
                multiBomb(firstRowIndex: rowOrigin, firstColIndex: colOrigin, secondRowIndex: rowDestination, secondColIndex: colDestination)
            } else if left == .gift && right == .row || left == .row && right == .gift {
                multiRow(firstRowIndex: rowOrigin, firstColIndex: colOrigin, secondRowIndex: rowDestination, secondColIndex: colDestination)
            } else if left == .gift && right == .column || left == .column && right == .gift {
                multiCol(firstRowIndex: rowOrigin, firstColIndex: colOrigin, secondRowIndex: rowDestination, secondColIndex: colDestination)
            } else if [left, right].allSatisfy({
                $0 == .bomb
            }) {
                multiBomb(firstRowIndex: rowOrigin, firstColIndex: colOrigin, secondRowIndex: rowDestination, secondColIndex: colDestination)
            } else if [.row, .column].contains(left) && right == .bomb || left == .bomb && [.row, .column].contains(right) {
                bigCross(firstRowIndex: rowOrigin, firstColIndex: colOrigin, secondRowIndex: rowDestination, secondColIndex: colDestination)
            } else if [.row, .column].contains(left) &&  [.row, .column].contains(right) {
                cross(firstRowIndex: rowOrigin, firstColIndex: colOrigin, secondRowIndex: rowDestination, secondColIndex: colDestination)
            } else if left == .gift {
                gift(rowIndex: rowOrigin, colIndex: colOrigin, icon: board[rowDestination][colDestination])
            } else if right == .gift {
                gift(rowIndex: rowDestination, colIndex: colDestination, icon: board[rowOrigin][colOrigin])
            } else if left == .bomb {
                bomb(rowIndex: rowOrigin, columnIndex: colOrigin)
            } else if right == .bomb {
                bomb(rowIndex: rowDestination, columnIndex: colDestination)
            } else if left == .row {
                rowActivate(rowIndex: rowOrigin, colIndex: colOrigin)
            } else if right == .row {
                rowActivate(rowIndex: rowDestination, colIndex: colDestination)
            } else if left == .column {
                colActivate(rowIndex: rowOrigin, colIndex: colOrigin)
            } else if right == .column {
                colActivate(rowIndex: rowDestination, colIndex: colDestination)
            } else {
                checkMatch()
            }
            //self.fall()
            runFunctionWithDelay(delay: 0.5) {
                self.checkMatch()
                if !self.isMatch {
                    self.checkMatch()
                    withAnimation(.easeInOut(duration: 0.4)) {
                        (self.board[rowOrigin][colOrigin], self.board[rowDestination][colDestination]) = (self.board[rowDestination][colDestination], self.board[rowOrigin][colOrigin])
                    }
                }
            }
        }
        
    }
    func extendTimerBasedOnScore() {
        let scoreIncreaseThreshold = 10
        let comboMultiplier = 2
        
        let baseExtension = score / scoreIncreaseThreshold
        let totalTimerExtension = baseExtension
        
        if gameTime < 200 {
            gameTime += Int(totalTimerExtension)
        }
        if gameTime >= 200 {
            gameTime = 200
        }
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.setValue(score, forKey: "bestScore")
        }
    }
}
