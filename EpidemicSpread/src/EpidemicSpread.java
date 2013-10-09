
import java.io.IOException;
import java.net.UnknownHostException;

import org.graphstream.stream.netstream.NetStreamReceiver;
import org.graphstream.stream.netstream.NetStreamSender;

public class EpidemicSpread {

	public static void main(String[] args) throws UnknownHostException, IOException {
		NetStreamReceiver receiver = new NetStreamReceiver(2001);
		new SimpleNetStreamViewer(receiver, true, 500, 500);
		new AcquaintedGraphAnalyser(receiver, new NetStreamSender(2002));
	}

}
