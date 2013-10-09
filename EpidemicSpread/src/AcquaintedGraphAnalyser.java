
import java.awt.Color;
import java.io.IOException;

import org.graphstream.algorithm.Toolkit;
import org.graphstream.graph.Graph;
import org.graphstream.graph.Node;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.ProxyPipe;
import org.graphstream.stream.SinkAdapter;
import org.graphstream.stream.netstream.NetStreamReceiver;
import org.graphstream.stream.netstream.NetStreamSender;

import org.graphstream.algorithm.BetweennessCentrality;

public class AcquaintedGraphAnalyser extends SinkAdapter{
	private NetStreamSender sender;
	private Graph graph;
	private String mySourceId;
	private long myTimeId;

	public AcquaintedGraphAnalyser(NetStreamReceiver receiver, NetStreamSender sender) {
		this.sender = sender;
		graph = new SingleGraph("acquainted", false, false);
		ProxyPipe pipe = receiver.getDefaultStream();
		pipe.addElementSink(graph);
		pipe.addElementSink(this);

		mySourceId = toString();
		myTimeId = 0;
	}

	@Override
	public void stepBegins(String sourceId, long timeId, double step) {
		BetweennessCentrality bc = new BetweennessCentrality();
		bc.setCentralityAttributeName("centrality");
		bc.init(graph);
		bc.compute();
		double c = Double.MIN_VALUE;
		for(Node n : graph){
			c = Math.max(c, n.getNumber("centrality"));
		}
		for(Node n : graph){
			sender.nodeAttributeAdded(mySourceId, myTimeId++, n.getId(), "centrality", n.getNumber("centrality")/c);
			//sender.nodeAttributeAdded(mySourceId, myTimeId++, n.getId(), "maxCentrality", c);
		}

		// sync
		sender.stepBegins(mySourceId, myTimeId++, step);

	}
}
