import ComposableArchitecture
import SwiftUI
//import SwiftUINavigation

@Reducer
struct AlarmForm {
  @ObservableState
  struct State: Equatable, Sendable {
    var focus: Field? = .title
    var alarm: Alarm

    init(focus: Field? = .title, alarm: Alarm) {
      self.focus = focus
      self.alarm = alarm
//      if self.syncUp.attendees.isEmpty {
//        @Dependency(\.uuid) var uuid
//        self.syncUp.attendees.append(Attendee(id: Attendee.ID(uuid())))
//      }
    }

    enum Field: Hashable {
      //case attendee(Attendee.ID)
      case title
    }
  }

  enum Action: BindableAction, Equatable, Sendable {
    //case addAttendeeButtonTapped
    case binding(BindingAction<State>)
    case alarmTimeChanged([String])
    //case deleteAttendees(atOffsets: IndexSet)
  }

  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
//      case .addAttendeeButtonTapped:
//        let attendee = Attendee(id: Attendee.ID(self.uuid()))
//        state.syncUp.attendees.append(attendee)
//        state.focus = .attendee(attendee.id)
//        return .none

      case .binding:
        return .none
        
      case .alarmTimeChanged(let newValue):
        state.alarm.time = newValue
        return .none

//      case let .deleteAttendees(atOffsets: indices):
//        state.syncUp.attendees.remove(atOffsets: indices)
//        if state.syncUp.attendees.isEmpty {
//          state.syncUp.attendees.append(Attendee(id: Attendee.ID(self.uuid())))
//        }
//        guard let firstIndex = indices.first
//        else { return .none }
//        let index = min(firstIndex, state.syncUp.attendees.count - 1)
//        state.focus = .attendee(state.syncUp.attendees[index].id)
//        return .none
      }
    }
  }
}

struct AlarmFormView: View {
  @Bindable var store: StoreOf<AlarmForm>
  @FocusState var focus: AlarmForm.State.Field?

  var body: some View {
    VStack {
      MultiPickerView(selection: $store.alarm.time.sending(\.alarmTimeChanged))
      Form {
        
        Section {
          TextField("Title", text: $store.alarm.title)
            .focused($focus, equals: .title)
          HStack {
            //          Slider(value: $store.syncUp.duration.minutes, in: 5...30, step: 1) {
            //            Text("Length")
            //          }
            Spacer()
            //Text(store.syncUp.duration.formatted(.units()))
          }
          //ThemePicker(selection: $store.syncUp.theme)
        } header: {
          Text("Sync-up Info")
        }
        Section {
          //        ForEach($store.syncUp.attendees) { $attendee in
          //          TextField("Name", text: $attendee.name)
          //            .focused($focus, equals: .attendee(attendee.id))
          //        }
          //        .onDelete { indices in
          //          store.send(.deleteAttendees(atOffsets: indices))
          //        }
          
          //        Button("New attendee") {
          //          store.send(.addAttendeeButtonTapped)
          //        }
        } header: {
          Text("Alarms")
        }
      }
      .bind($store.focus, to: $focus)
    }
  }
}

//struct ThemePicker: View {
//  @Binding var selection: Theme
//
//  var body: some View {
//    Picker("Theme", selection: self.$selection) {
//      ForEach(Theme.allCases) { theme in
//        ZStack {
//          RoundedRectangle(cornerRadius: 4)
//            .fill(theme.mainColor)
//          Label(theme.name, systemImage: "paintpalette")
//            .padding(4)
//        }
//        .foregroundColor(theme.accentColor)
//        .fixedSize(horizontal: false, vertical: true)
//        .tag(theme)
//      }
//    }
//  }
//}

extension Duration {
  fileprivate var minutes: Double {
    get { Double(self.components.seconds / 60) }
    set { self = .seconds(newValue * 60) }
  }
}

//#Preview {
//  NavigationStack {
//    AlarmFormView(
//      store: Store(initialState: Alarm.State(alarm: )) {
//        AlarmForm()
//      }
//    )
//  }
//}

public struct MultiPickerView: View  {
  
  @Binding var selection: [String]
  
  public init(selection: Binding<[String]>) {
    self._selection = selection
  }
  
  var timeData: [(String, [String])] = [
    ("Hour", Array(1...12).map { String(format: "%02d", $0) }),
    ("Minute", Array(0...59).map { String(format: "%02d", $0) }),
    ("Period", ["AM", "PM"])
  ]
  
  public var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        ForEach(0..<self.timeData.count, id: \.self) { column in
          Picker(self.timeData[column].0, selection: self.$selection[column]) {
            ForEach(0..<self.timeData[column].1.count, id: \.self) { row in
              Text(verbatim:self.timeData[column].1[row])
                .tag(self.timeData[column].1[row])
                .foregroundColor(.white)
            }
          }
          .pickerStyle(WheelPickerStyle())
          .frame(width: geometry.size.width / 3, height: 100)
          .clipped()
        }
      }
    }
  }
}
